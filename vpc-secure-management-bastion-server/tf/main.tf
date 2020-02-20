provider "ibm" {
  region           = var.region
  ibmcloud_api_key = var.ibmcloud_api_key
  generation       = var.generation
  ibmcloud_timeout = var.ibmcloud_timeout
}

locals {
  BASENAME = "${var.prefix}vpc-pubpriv"
}

data "ibm_resource_group" "all_rg" {
  name = var.resource_group_name
}

resource "ibm_is_vpc" "vpc" {
  name           = local.BASENAME
  resource_group = data.ibm_resource_group.all_rg.id
}

resource "ibm_is_subnet" "bastion" {
  name                     = "${local.BASENAME}-bastion-subnet"
  vpc                      = ibm_is_vpc.vpc.id
  zone                     = var.zone
  total_ipv4_address_count = 256
  resource_group           = data.ibm_resource_group.all_rg.id
}

module "map_gen1_to_gen2" {
  source     = "../../tfshared/map-gen1-to-gen2/"
  generation = var.generation
  image      = var.image_name
  profile    = var.profile
}

data "ibm_is_image" "os" {
  name = module.map_gen1_to_gen2.image
}

data "ibm_is_ssh_key" "sshkey" {
  name = var.ssh_key_name
}

module "bastion" {
  source                   = "../tfmodule"
  basename                 = local.BASENAME
  ibm_is_vpc_id            = ibm_is_vpc.vpc.id
  ibm_is_resource_group_id = data.ibm_resource_group.all_rg.id
  zone                     = var.zone
  remote                   = "0.0.0.0/0"
  profile                  = module.map_gen1_to_gen2.profile
  ibm_is_image_id          = data.ibm_is_image.os.id
  ibm_is_ssh_key_id        = data.ibm_is_ssh_key.sshkey.id
  ibm_is_subnet_id         = ibm_is_subnet.bastion.id
}

