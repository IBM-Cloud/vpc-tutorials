data "ibm_resource_group" "group" {
  name = var.resource_group_name
}

locals {
  tags     = []
  resource_group = data.ibm_resource_group.group
  
  name     = var.prefix
  cidr     = "10.0.0.0/16"
  zone = "${var.region}-1"
}

resource "ibm_is_vpc" "main" {
  name                      = local.name
  resource_group            = local.resource_group.id
  address_prefix_management = "manual"
  tags                      = local.tags
}
resource "ibm_is_vpc_address_prefix" "main0" {
  name     = local.name
  zone     = local.zone
  vpc      = ibm_is_vpc.main.id
  cidr     = cidrsubnet(local.cidr, 8, 0)
}
resource "ibm_is_subnet" "main0" {
  name            = local.name
  vpc             = ibm_is_vpc.main.id
  zone            = local.zone
  ipv4_cidr_block = ibm_is_vpc_address_prefix.main0.cidr
  resource_group            = local.resource_group.id
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

output vpc_id {
  value = ibm_is_vpc.main.id
}
output zone {
  value = ibm_is_subnet.main0.zone
}
output subnet_id {
  value = ibm_is_subnet.main0.id
}
output resource_group_id {
  value  = local.resource_group.id
}
