provider "ibm" {
  region                = var.region
  ibmcloud_api_key      = var.ibmcloud_api_key
  generation            = var.generation
  iaas_classic_username = var.iaas_classic_username
  iaas_classic_api_key  = var.iaas_classic_api_key
  ibmcloud_timeout      = var.ibmcloud_timeout
}

locals {
  BASENAME = "${var.prefix}-vpc"

  user_data_cloud = <<EOF
#!/bin/bash
apt-get update
apt-get install -y nodejs npm
EOF

}

module "map_gen1_to_gen2" {
  generation = var.generation
  source     = "../../tfshared/map-gen1-to-gen2/"
  image      = var.cloud_image_name
  profile    = var.profile
}

data "ibm_resource_group" "all_rg" {
  name = var.resource_group_name
}

resource "ibm_is_vpc" "vpc" {
  name           = var.vpc_name == "" ? local.BASENAME : var.vpc_name
  resource_group = data.ibm_resource_group.all_rg.id
}

resource "ibm_is_public_gateway" "cloud" {
  count = var.cloud_pgw ? 1 : 0
  vpc   = ibm_is_vpc.vpc.id
  name  = "${local.BASENAME}-${var.zone}-pubgw"
  zone  = var.zone
}

resource "ibm_is_public_gateway" "bastion" {
  count = var.bastion_pgw ? 1 : 0
  vpc   = ibm_is_vpc.vpc.id
  name  = "${local.BASENAME}-${var.zone}-pubgw"
  zone  = var.zone
}

resource "ibm_is_subnet" "cloud" {
  name                     = "${local.BASENAME}-cloud-subnet"
  vpc                      = ibm_is_vpc.vpc.id
  zone                     = var.zone
  public_gateway           = join("", ibm_is_public_gateway.cloud.*.id)
  total_ipv4_address_count = 256
  resource_group           = data.ibm_resource_group.all_rg.id
}

# bastion subnet and instance values needed by the bastion module
resource "ibm_is_subnet" "bastion" {
  name                     = "${local.BASENAME}-bastion-subnet"
  vpc                      = ibm_is_vpc.vpc.id
  zone                     = var.zone
  total_ipv4_address_count = 256
  resource_group           = data.ibm_resource_group.all_rg.id
}

data "ibm_is_image" "os" {
  name = module.map_gen1_to_gen2.image
}

data "ibm_is_ssh_key" "sshkey" {
  name = var.ssh_key_name
}

locals {
  bastion_ingress_cidr    = "0.0.0.0/0" # DANGER: cidr range that can ssh to the bastion when maintenance is enabled
  maintenance_egress_cidr = "0.0.0.0/0" # cidr range required to contact software repositories when maintenance is enabled
}

module "bastion" {
  source                   = "../../vpc-secure-management-bastion-server/tfmodule"
  basename                 = local.BASENAME
  ibm_is_vpc_id            = ibm_is_vpc.vpc.id
  ibm_is_resource_group_id = data.ibm_resource_group.all_rg.id
  zone                     = var.zone
  remote                   = local.bastion_ingress_cidr
  profile                  = module.map_gen1_to_gen2.profile
  ibm_is_image_id          = data.ibm_is_image.os.id
  ibm_is_ssh_key_id        = data.ibm_is_ssh_key.sshkey.id
  ibm_is_subnet_id         = ibm_is_subnet.bastion.id
}

# maintenance will require ingress from the bastion, so the bastion has output a maintenance SG
# maintenance may also include installing new versions of open source software that are not in the IBM mirrors
# add the additional egress required to the maintenance security group exported by the bastion
# for example at 53 DNS, 80 http, and 443 https probably make sense
resource "ibm_is_security_group_rule" "maintenance_egress_443" {
  group     = module.bastion.security_group_id
  direction = "outbound"
  remote    = local.maintenance_egress_cidr

  tcp {
    port_min = "443"
    port_max = "443"
  }
}

resource "ibm_is_security_group_rule" "maintenance_egress_80" {
  group     = module.bastion.security_group_id
  direction = "outbound"
  remote    = "0.0.0.0/0"

  tcp {
    port_min = 80
    port_max = 80
  }
}

resource "ibm_is_security_group_rule" "maintenance_egress_53" {
  group     = module.bastion.security_group_id
  direction = "outbound"
  remote    = "0.0.0.0/0"

  tcp {
    port_min = 53
    port_max = 53
  }
}

resource "ibm_is_security_group_rule" "maintenance_egress_udp_53" {
  group     = module.bastion.security_group_id
  direction = "outbound"
  remote    = "0.0.0.0/0"

  udp {
    port_min = 53
    port_max = 53
  }
}

resource "ibm_is_security_group" "cloud" {
  name           = "${local.BASENAME}-sg"
  vpc            = ibm_is_vpc.vpc.id
  resource_group = data.ibm_resource_group.all_rg.id
}

resource "ibm_is_security_group_rule" "cloud_ingress_tcp_80" {
  group     = ibm_is_security_group.cloud.id
  direction = "inbound"
  remote    = "0.0.0.0/0"

  tcp {
    port_min = 80
    port_max = 80
  }
}

resource "ibm_is_security_group_rule" "cloud_ingress_tcp_443" {
  group     = ibm_is_security_group.cloud.id
  direction = "inbound"
  remote    = "0.0.0.0/0"

  tcp {
    port_min = 443
    port_max = 443
  }
}

resource "ibm_is_security_group_rule" "cloud_ingress_tcp_22" {
  group     = ibm_is_security_group.cloud.id
  direction = "inbound"
  remote    = "0.0.0.0/0"

  tcp {
    port_min = 22
    port_max = 22
  }
}

resource "ibm_is_security_group_rule" "cloud_ingress_icmp_8" {
  group     = ibm_is_security_group.cloud.id
  direction = "inbound"
  remote    = "0.0.0.0/0"

  icmp {
    type = 8
  }
}

resource "ibm_is_security_group_rule" "cloud_egress_tcp_all" {
  group     = ibm_is_security_group.cloud.id
  direction = "outbound"
  remote    = "0.0.0.0/0"
}

#Cloud
locals {
  # create either [cloud] or [cloud, maintenance] depending on the var.maintenance boolean
  cloud_security_groups = split(
    ",",
    var.maintenance ? format(
      "%s,%s",
      ibm_is_security_group.cloud.id,
      module.bastion.security_group_id,
    ) : ibm_is_security_group.cloud.id,
  )
}

resource "ibm_is_instance" "cloud" {
  name           = "${local.BASENAME}-cloud-vsi"
  image          = data.ibm_is_image.os.id
  profile        = module.map_gen1_to_gen2.profile
  vpc            = ibm_is_vpc.vpc.id
  zone           = var.zone
  keys           = [data.ibm_is_ssh_key.sshkey.id]
  user_data      = local.user_data_cloud
  resource_group = data.ibm_resource_group.all_rg.id

  primary_network_interface {
    subnet = ibm_is_subnet.cloud.id
    # TF-UPGRADE-TODO: In Terraform v0.10 and earlier, it was sometimes necessary to
    # force an interpolation expression to be interpreted as a list by wrapping it
    # in an extra set of list brackets. That form was supported for compatibility in
    # v0.11, but is no longer supported in Terraform v0.12.
    #
    # If the expression in the following list itself returns a list, remove the
    # brackets to avoid interpretation as a list of lists. If the expression
    # returns a single list item then leave it as-is and remove this TODO comment.
    security_groups = flatten([local.cloud_security_groups])
  }
}

data "ibm_compute_ssh_key" "sshkey" {
  label = var.onprem_ssh_key_name
}

# Create a virtual server with the SSH key
resource "ibm_compute_vm_instance" "onprem" {
  hostname          = "${local.BASENAME}-onprem-vsi"
  domain            = "solution-tutorial.cloud.ibm"
  ssh_key_ids       = [data.ibm_compute_ssh_key.sshkey.id]
  os_reference_code = var.onprem_image_name
  datacenter        = var.onprem_datacenter
  network_speed     = 100
  cores             = 1
  memory            = 1024
}

locals {
  bastion_ip = module.bastion.floating_ip_address
}

output "output_summary" {
  value = <<SUMMARY
  #
  # Your "on-prem" strongSwan VSI public IP address: ${ibm_compute_vm_instance.onprem.ipv4_address}
  # Your cloud bastion IP address: ${local.bastion_ip}
  # Your cloud VPC/VSI microservice private IP address: ${ibm_is_instance.cloud.primary_network_interface[0].primary_ipv4_address}

  # if the ssh key is not the default for ssh try the -I PATH_TO_PRIVATE_KEY_FILE option
  # from your machine to the onprem VSI
  # ssh root@${ibm_compute_vm_instance.onprem.ipv4_address}
  # from your machine to the bastion
  # ssh root@${local.bastion_ip}
  # from your machine to the cloud VSI jumping through the bastion
  # ssh -J root@${local.bastion_ip} root@${ibm_is_instance.cloud.primary_network_interface[0].primary_ipv4_address}
  # from the bastion VSI to the cloud VSI
  # ssh root@${ibm_is_instance.cloud.primary_network_interface[0].primary_ipv4_address}

  # When the VPN gateways are connected you will be able to ssh between them over the VPN connection:
  # From your machine see if you can jump through the onprem VSI through the VPN gateway to the cloud VSI:
  # ssh -J root@${ibm_compute_vm_instance.onprem.ipv4_address} root@${ibm_is_instance.cloud.primary_network_interface[0].primary_ipv4_address}
  # From your machine see if you can jump through the bastion to the cloud VSI through the VPN to the onprem VSI 
  # ssh -J root@BASTION_IP_ADDRESS,root@${ibm_is_instance.cloud.primary_network_interface[0].primary_ipv4_address} root@$${ibm_compute_vm_instance.onprem.ipv4_address}
  # From the bastion jump through the cloud VSI through the VPN to the onprem VSI:
  # ssh -J root@${ibm_is_instance.cloud.primary_network_interface[0].primary_ipv4_address} root@${ibm_compute_vm_instance.onprem.ipv4_address}

  # The following will be used by the strongSwan initialize script:
  PRESHARED_KEY="20_PRESHARED_KEY_KEEP_SECRET_19"
  CLOUD_CIDR=${ibm_is_subnet.cloud.ipv4_cidr_block}
  VSI_CLOUD_IP=${ibm_is_instance.cloud.primary_network_interface[0].primary_ipv4_address}
  SUB_CLOUD_NAME=${ibm_is_subnet.cloud.name}

  ONPREM_CIDR=${ibm_compute_vm_instance.onprem.private_subnet}
  VSI_ONPREM_IP=${ibm_compute_vm_instance.onprem.ipv4_address}

  BASTION_IP_ADDRESS=${local.bastion_ip}

  # Use this command to access the cloud VSI with the bastion VSI as jump host:
  # ssh -J root@${local.bastion_ip} root@${ibm_is_instance.cloud.primary_network_interface[0].primary_ipv4_address}
    
SUMMARY

}

