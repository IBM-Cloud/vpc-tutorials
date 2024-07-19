data "ibm_is_image" "ds_image" {
  name = "ibm-centos-stream-9-amd64-8"
}

data "ibm_is_ssh_key" "ds_key" {
  name = var.ssh_keyname
}

data "ibm_resource_group" "group" {
  name = var.resource_group_name
}

resource "ibm_is_vpc" "vpc" {
  name           = var.vpc_name
  resource_group = data.ibm_resource_group.group.id
}

resource "ibm_is_public_gateway" "cloud" {
  vpc   = ibm_is_vpc.vpc.id
  name  = "${var.basename}-pubgw"
  zone  = var.subnet_zone
}

resource "ibm_is_vpc_address_prefix" "vpc_address_prefix" {
  name = "${var.basename}-prefix"
  zone = var.subnet_zone
  vpc  = ibm_is_vpc.vpc.id
  cidr = "192.168.0.0/16"
}

resource "ibm_is_subnet" "subnet" {
  name            = "${var.basename}-subnet"
  vpc             = ibm_is_vpc.vpc.id
  zone            = var.subnet_zone
  resource_group  = data.ibm_resource_group.group.id
  ipv4_cidr_block = ibm_is_vpc_address_prefix.vpc_address_prefix.cidr
}

resource "ibm_is_instance" "instance" {
  name           = "${var.basename}-instance"
  vpc            = ibm_is_vpc.vpc.id
  zone           = var.subnet_zone
  profile        = "cx2-2x4"
  image          = data.ibm_is_image.ds_image.id
  keys           = [data.ibm_is_ssh_key.ds_key.id]
  resource_group = data.ibm_resource_group.group.id

  primary_network_interface {
    subnet = ibm_is_subnet.subnet.id
  }
}
