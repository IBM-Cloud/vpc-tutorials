data "ibm_resource_group" "group" {
  name = var.resource_group_name
}
data "ibm_is_image" "image" {
  name = var.instance_image_name
}
data "ibm_is_ssh_key" "ssh_key" {
  name = var.vpc_ssh_key_name
}

locals {
  tags = [
    "prefix:${var.prefix}",
    lower(replace("dir:${abspath(path.root)}", "/", "_")),
  ]
  resource_group = data.ibm_resource_group.group

  name = var.prefix
  cidr = "10.0.0.0/16"
  zone = "${var.region}-1"
}

resource "ibm_is_vpc" "main" {
  name                      = local.name
  tags                      = local.tags
  resource_group            = local.resource_group.id
  address_prefix_management = "manual"
}
resource "ibm_is_vpc_address_prefix" "main0" {
  name = local.name
  zone = local.zone
  vpc  = ibm_is_vpc.main.id
  cidr = cidrsubnet(local.cidr, 8, 0)
}
resource "ibm_is_subnet" "main0" {
  name            = local.name
  tags            = local.tags
  vpc             = ibm_is_vpc.main.id
  zone            = local.zone
  ipv4_cidr_block = ibm_is_vpc_address_prefix.main0.cidr
  resource_group  = local.resource_group.id
}

resource "ibm_is_security_group_rule" "inbound_all" {
  group     = ibm_is_vpc.main.default_security_group
  direction = "inbound"
  remote    = "0.0.0.0/0"
}
resource "ibm_is_security_group_rule" "outbound_all" {
  group     = ibm_is_vpc.main.default_security_group
  direction = "outbound"
  remote    = "0.0.0.0/0"
}
resource "ibm_is_volume" "vol0" {
  name           = "${local.name}0"
  tags           = local.tags
  resource_group = local.resource_group.id
  profile        = "10iops-tier"
  capacity       = 10
  zone           = ibm_is_subnet.main0.zone
}
resource "ibm_is_volume" "vol1" {
  name           = "${local.name}1"
  tags           = local.tags
  resource_group = local.resource_group.id
  profile        = "10iops-tier"
  capacity       = 11
  zone           = ibm_is_subnet.main0.zone
}
resource "ibm_is_instance" "main0" {
  name           = local.name
  tags           = local.tags
  vpc            = ibm_is_vpc.main.id
  resource_group = local.resource_group.id
  zone           = ibm_is_subnet.main0.zone
  keys           = [data.ibm_is_ssh_key.ssh_key.id]
  image          = data.ibm_is_image.image.id
  profile        = var.profile
  volumes        = [ibm_is_volume.vol0.id, ibm_is_volume.vol1.id]

  primary_network_interface {
    subnet = ibm_is_subnet.main0.id
  }
  user_data = file("${path.module}/user_data.sh")
}
resource "ibm_is_floating_ip" "main0" {
  tags           = local.tags
  resource_group = local.resource_group.id
  name           = local.name
  target         = ibm_is_instance.main0.primary_network_interface[0].id
}

data "ibm_is_volume" "main0" {
  name = ibm_is_instance.main0.boot_volume[0].name
}

resource "ibm_resource_tag" "main0_boot" {
  resource_id = data.ibm_is_volume.main0.crn
  tags        = local.tags
}

output "resource_group_id" {
  value = local.resource_group.id
}
output "vpc_id" {
  value = ibm_is_vpc.main.id
}
output "zone" {
  value = ibm_is_subnet.main0.zone
}
output "subnet_id" {
  value = ibm_is_subnet.main0.id
}
output "instance_id" {
  value = ibm_is_instance.main0.id
}
output "floating_ip" {
  value = ibm_is_floating_ip.main0.address
}
output "profile" {
  value = var.profile
}
output "key" {
  value = data.ibm_is_ssh_key.ssh_key.id
}
output "z" {
  value = {
    ssh = "ssh root@${ibm_is_floating_ip.main0.address}"
  }
}
