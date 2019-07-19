provider "ibm" {
  region             = "us-south"
  ibmcloud_api_key   = "${var.ibmcloud_api_key}"
  generation         = 1
  softlayer_username = "${var.softlayer_username}"
  softlayer_api_key  = "${var.softlayer_api_key}"
}

locals {
  BASENAME = "${var.prefix}-vpc"

  user_data_cloud = <<EOF
#!/bin/bash
apt-get update
apt-get install -y nodejs npm
EOF
}

data "ibm_resource_group" "all_rg" {
  name = "${var.resource_group_name}"
}

resource "ibm_is_vpc" "vpc" {
  name           = "${var.vpc_name == "" ? local.BASENAME : var.vpc_name}"
  resource_group = "${data.ibm_resource_group.all_rg.id}"
}

resource "ibm_is_public_gateway" "cloud" {
  count = "${var.cloud_pgw?1:0}"
  vpc   = "${ibm_is_vpc.vpc.id}"
  name  = "${local.BASENAME}-${var.zone_vsi}-pubgw"
  zone  = "${var.zone_vsi}"
}

resource "ibm_is_public_gateway" "bastion" {
  count = "${var.bastion_pgw?1:0}"
  vpc   = "${ibm_is_vpc.vpc.id}"
  name  = "${local.BASENAME}-${var.zone_bastion}-pubgw"
  zone  = "${var.zone_bastion}"
}

resource "ibm_is_subnet" "cloud" {
  name                     = "${local.BASENAME}-cloud-subnet"
  vpc                      = "${ibm_is_vpc.vpc.id}"
  zone                     = "${var.zone_vsi}"
  public_gateway           = "${join("", ibm_is_public_gateway.cloud.*.id)}"
  total_ipv4_address_count = 256
}

# bastion subnet and instance values needed by the bastion module
resource "ibm_is_subnet" "bastion" {
  name                     = "${local.BASENAME}-bastion-subnet"
  vpc                      = "${ibm_is_vpc.vpc.id}"
  zone                     = "${var.zone_bastion}"
  total_ipv4_address_count = 256
}

data "ibm_is_image" "os" {
  name = "${var.image_name}"
}

data "ibm_is_ssh_key" "sshkey" {
  name = "${var.ssh_key_name}"
}

locals {
  bastion_ingress_cidr    = "0.0.0.0/0" # DANGER: cidr range that can ssh to the bastion when maintenance is enabled
  maintenance_egress_cidr = "0.0.0.0/0" # cidr range required to contact software repositories when maintenance is enabled
}

module bastion {
  source            = "../../vpc-secure-management-bastion-server/tfmodule"
  basename          = "${local.BASENAME}"
  ibm_is_vpc_id     = "${ibm_is_vpc.vpc.id}"
  zone              = "${var.zone_bastion}"
  remote            = "${local.bastion_ingress_cidr}"
  profile           = "${var.profile}"
  ibm_is_image_id   = "${data.ibm_is_image.os.id}"
  ibm_is_ssh_key_id = "${data.ibm_is_ssh_key.sshkey.id}"
  ibm_is_subnet_id  = "${ibm_is_subnet.bastion.id}"
}

# maintenance will require ingress from the bastion, so the bastion has output a maintenance SG
# maintenance may also include installing new versions of open source software that are not in the IBM mirrors
# add the additional egress required to the maintenance security group exported by the bastion
# for example at 53 DNS, 80 http, and 443 https probably make sense
resource "ibm_is_security_group_rule" "maintenance_egress_443" {
  group     = "${module.bastion.security_group_id}"
  direction = "egress"
  remote    = "${local.maintenance_egress_cidr}"

  tcp = {
    port_min = "443"
    port_max = "443"
  }
}

resource "ibm_is_security_group_rule" "maintenance_egress_80" {
  group     = "${module.bastion.security_group_id}"
  direction = "egress"
  remote    = "0.0.0.0/0"

  tcp = {
    port_min = 80
    port_max = 80
  }
}

resource "ibm_is_security_group_rule" "maintenance_egress_53" {
  group     = "${module.bastion.security_group_id}"
  direction = "egress"
  remote    = "0.0.0.0/0"

  tcp = {
    port_min = 53
    port_max = 53
  }
}

resource "ibm_is_security_group_rule" "maintenance_egress_udp_53" {
  group     = "${module.bastion.security_group_id}"
  direction = "egress"
  remote    = "0.0.0.0/0"

  udp = {
    port_min = 53
    port_max = 53
  }
}

resource "ibm_is_security_group" "cloud" {
  name = "${local.BASENAME}-sg"
  vpc  = "${ibm_is_vpc.vpc.id}"
}

resource "ibm_is_security_group_rule" "cloud_ingress_tcp_80" {
  group     = "${ibm_is_security_group.cloud.id}"
  direction = "ingress"
  remote    = "0.0.0.0/0"

  tcp = {
    port_min = 80
    port_max = 80
  }
}

resource "ibm_is_security_group_rule" "cloud_ingress_tcp_443" {
  group     = "${ibm_is_security_group.cloud.id}"
  direction = "ingress"
  remote    = "0.0.0.0/0"

  tcp = {
    port_min = 443
    port_max = 443
  }
}

resource "ibm_is_security_group_rule" "cloud_ingress_tcp_22" {
  group     = "${ibm_is_security_group.cloud.id}"
  direction = "ingress"
  remote    = "0.0.0.0/0"

  tcp = {
    port_min = 22
    port_max = 22
  }
}

resource "ibm_is_security_group_rule" "cloud_ingress_icmp_8" {
  group     = "${ibm_is_security_group.cloud.id}"
  direction = "ingress"
  remote    = "0.0.0.0/0"

  icmp = {
    type = 8
  }
}

resource "ibm_is_security_group_rule" "cloud_egress_tcp_all" {
  group     = "${ibm_is_security_group.cloud.id}"
  direction = "egress"
  remote    = "0.0.0.0/0"
}

#Cloud
locals {
  # create either [cloud] or [cloud, maintenance] depending on the var.maintenance boolean
  cloud_security_groups = "${split(",", var.maintenance ? format("%s,%s", ibm_is_security_group.cloud.id, module.bastion.security_group_id) : ibm_is_security_group.cloud.id)}"
}

resource "ibm_is_instance" "cloud" {
  name      = "${local.BASENAME}-cloud-vsi"
  image     = "${data.ibm_is_image.os.id}"
  profile   = "${var.profile}"
  vpc       = "${ibm_is_vpc.vpc.id}"
  zone      = "${var.zone_vsi}"
  keys      = ["${data.ibm_is_ssh_key.sshkey.id}"]
  user_data = "${local.user_data_cloud}"

  primary_network_interface = {
    subnet          = "${ibm_is_subnet.cloud.id}"
    security_groups = ["${local.cloud_security_groups}"]
  }
}

data "ibm_compute_ssh_key" "sshkey" {
  label = "${var.softlayer_ssh_key_name}"
}

# Create a virtual server with the SSH key
resource "ibm_compute_vm_instance" "onprem" {
  hostname          = "${local.BASENAME}-onprem-vsi"
  domain            = "solution-tutorial.cloud.ibm"
  ssh_key_ids       = ["${data.ibm_compute_ssh_key.sshkey.id}"]
  os_reference_code = "${var.softlayer_image_name}"
  datacenter        = "${var.softlayer_datacenter}"
  network_speed     = 100
  cores             = 1
  memory            = 1024
}

locals {
  bastion_ip = "${module.bastion.floating_ip_address}"
}

output "BASTION_IP_ADDRESS" {
  value = "${local.bastion_ip}"
}

output "sshbastion" {
  value = "ssh root@${local.bastion_ip}"
}

output "sshcloud" {
  value = "ssh -o ProxyJump=root@${local.bastion_ip} root@${ibm_is_instance.cloud.primary_network_interface.0.primary_ipv4_address}"
}

output "CLOUD_CIDR" {
  value = "${ibm_is_subnet.cloud.ipv4_cidr_block}"
}

output "VSI_CLOUD_IP" {
  value = "${ibm_is_instance.cloud.primary_network_interface.0.primary_ipv4_address}"
}

output "ONPREM_CIDR" {
  value = "${ibm_compute_vm_instance.onprem.private_subnet}"
}

output "VSI_ONPREM_IP" {
  value = "${ibm_compute_vm_instance.onprem.ipv4_address}"
}
