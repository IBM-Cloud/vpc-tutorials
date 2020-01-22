provider "ibm" {
  ibmcloud_api_key = var.ibmcloud_api_key
  ibmcloud_timeout = 300
  generation       = var.generation
  region           = var.vpc_region
}

data "ibm_resource_group" "group" {
  name = var.resource_group
}

resource "ibm_is_vpc" "vpc" {
  name           = "${var.resources_prefix}-vpc"
  resource_group = data.ibm_resource_group.group.id
}

data "ibm_is_ssh_key" "ssh_key" {
  count = length(var.vpc_ssh_keys)
  name  = var.vpc_ssh_keys[count.index]
}

resource "ibm_is_public_gateway" "pgw" {
  count = "3"
  name  = "${var.resources_prefix}-pgw-${count.index + 1}"
  vpc   = ibm_is_vpc.vpc.id
  zone  = var.vpc_zones["${var.vpc_region}-availability-zone-${count.index + 1}"]
}

