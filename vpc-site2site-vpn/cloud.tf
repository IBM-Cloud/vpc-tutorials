# cloud vpc resources

resource "ibm_is_vpc" "cloud" {
  name                      = local.BASENAME_CLOUD
  tags                      = local.tags
  resource_group            = data.ibm_resource_group.all_rg.id
  address_prefix_management = "manual"
}

resource "ibm_is_vpc_address_prefix" "cloud" {
  name = "${local.BASENAME_CLOUD}-${local.zone}"
  zone = local.zone
  vpc  = ibm_is_vpc.cloud.id
  cidr = local.cidr_cloud_1
}

resource "ibm_is_public_gateway" "cloud" {
  count          = var.cloud_pgw ? 1 : 0
  resource_group = data.ibm_resource_group.all_rg.id
  vpc            = ibm_is_vpc.cloud.id
  name           = "${local.BASENAME_CLOUD}-${local.zone}-pubgw"
  zone           = local.zone
}

resource "ibm_is_public_gateway" "bastion" {
  count          = var.bastion_pgw ? 1 : 0
  resource_group = data.ibm_resource_group.all_rg.id
  vpc            = ibm_is_vpc.cloud.id
  name           = "${local.BASENAME_CLOUD}-${local.zone}-pubgw"
  zone           = local.zone
}


resource "ibm_is_subnet" "cloud" {
  depends_on      = [ibm_is_vpc_address_prefix.cloud]
  name            = "${local.BASENAME_CLOUD}-cloud"
  resource_group  = data.ibm_resource_group.all_rg.id
  vpc             = ibm_is_vpc.cloud.id
  zone            = local.zone
  ipv4_cidr_block = local.cidr_cloud_subnet
  public_gateway  = join("", ibm_is_public_gateway.cloud.*.id)
}

# bastion subnet and instance values needed by the bastion module
resource "ibm_is_subnet" "bastion" {
  depends_on      = [ibm_is_vpc_address_prefix.cloud]
  name            = "${local.BASENAME_CLOUD}-bastion"
  resource_group  = data.ibm_resource_group.all_rg.id
  vpc             = ibm_is_vpc.cloud.id
  zone            = local.zone
  ipv4_cidr_block = local.cidr_cloud_bastion
  public_gateway  = join("", ibm_is_public_gateway.bastion.*.id)
}


resource "ibm_is_vpn_gateway" "cloud" {
  name           = local.BASENAME_CLOUD
  resource_group = data.ibm_resource_group.all_rg.id
  subnet         = ibm_is_subnet.cloud.id
  mode           = "policy"
  tags           = local.tags
}

resource "ibm_is_vpn_gateway_connection" "cloud" {
  name           = local.BASENAME_CLOUD
  vpn_gateway    = ibm_is_vpn_gateway.cloud.id
  peer_address   = ibm_is_floating_ip.onprem.address
  preshared_key  = local.PRESHARED_KEY
  admin_state_up = true
  local_cidrs    = [local.cidr_cloud_1]
  peer_cidrs     = [local.cidr_onprem_1]
}

/*------------------------*/

locals {
  user_data_cloud = <<-EOF
  #!/bin/bash
  export DEBIAN_FRONTEND=noninteractive
  apt -qq -y update < /dev/null
  apt -qq -y install nodejs npm < /dev/null
EOF
}

locals {
  bastion_ingress_cidr    = "0.0.0.0/0" # DANGER: cidr range that can ssh to the bastion when maintenance is enabled
  maintenance_egress_cidr = "0.0.0.0/0" # cidr range required to contact software repositories when maintenance is enabled
}

module "bastion" {
  source                   = "../vpc-secure-management-bastion-server/tfmodule"
  basename                 = local.BASENAME_CLOUD
  ibm_is_vpc_id            = ibm_is_vpc.cloud.id
  ibm_is_resource_group_id = data.ibm_resource_group.all_rg.id
  zone                     = local.zone
  remote                   = local.bastion_ingress_cidr
  profile                  = var.profile
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
  name           = "${local.BASENAME_CLOUD}-sg"
  vpc            = ibm_is_vpc.cloud.id
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
  name           = local.BASENAME_CLOUD
  image          = data.ibm_is_image.os.id
  profile        = var.profile
  vpc            = ibm_is_vpc.cloud.id
  zone           = local.zone
  keys           = [data.ibm_is_ssh_key.sshkey.id]
  user_data      = local.user_data_cloud
  resource_group = data.ibm_resource_group.all_rg.id

  primary_network_interface {
    subnet          = ibm_is_subnet.cloud.id
    security_groups = flatten([local.cloud_security_groups])
  }
}

locals {
  bastion_ip = module.bastion.floating_ip_address
}
