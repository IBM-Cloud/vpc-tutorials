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

#Create a ssh keypair which will be used to provision code onto the system - and also access the VM for debug if needed.
resource "tls_private_key" "build_key" {
  count = var.ssh_private_key_format == "build" ? 1 : 0
  algorithm = "RSA"
  rsa_bits = "4096"
}

resource "ibm_is_ssh_key" "build_key" {
  count = var.ssh_private_key_format == "build" ? 1 : 0
  name = "${var.resources_prefix}-build-key"
  public_key = tls_private_key.build_key.0.public_key_openssh
  resource_group = data.ibm_resource_group.group.id
}

# data "ibm_is_ssh_key" "ssh_key" {
#   count = length(var.vpc_ssh_keys)
#   name  = var.vpc_ssh_keys[count.index]
# }

data "ibm_is_ssh_key" "ssh_key" {
  # count = 1
  name = var.vpc_ssh_key
}

resource "ibm_is_public_gateway" "pgw" {
  count = 3
  name  = "${var.resources_prefix}-pgw-${count.index + 1}"
  vpc   = ibm_is_vpc.vpc.id
  zone  = "${var.vpc_region}-${count.index + 1}"
  resource_group = data.ibm_resource_group.group.id
}

