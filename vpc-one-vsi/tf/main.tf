module map_gen1_to_gen2 {
  generation = var.generation
  source = "../../tfshared/map-gen1-to-gen2/"
  image = "centos-7.x-amd64"
  profile = "cc1-2x4"
}

data "ibm_is_image" "ds_image" {
  name = module.map_gen1_to_gen2.image
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
  ipv4_cidr_block = ibm_is_vpc_address_prefix.vpc_address_prefix.cidr
}

resource "ibm_is_instance" "instance" {
  name           = "${var.basename}-instance"
  vpc            = ibm_is_vpc.vpc.id
  zone           = var.subnet_zone
  profile        = module.map_gen1_to_gen2.profile
  image          = data.ibm_is_image.ds_image.id
  keys           = [data.ibm_is_ssh_key.ds_key.id]
  resource_group = data.ibm_resource_group.group.id

  primary_network_interface {
    subnet = ibm_is_subnet.subnet.id
  }
}
