# VPC with one subnet, one VSI and a floating IP
provider "ibm" {
  region           = var.ibm_region
  generation       = var.generation
}

resource "ibm_is_vpc" "vpc" {
  name = var.basename
}

# vsi1 access 
resource "ibm_is_security_group" "sg1" {
  name = "${var.basename}-sg1"
  vpc  = ibm_is_vpc.vpc.id
}

resource "ibm_is_subnet" "subnet1" {
  name                     = "${var.basename}-subnet1"
  vpc                      = ibm_is_vpc.vpc.id
  zone                     = var.ibm_zones[0]
  total_ipv4_address_count = 256
}

data "ibm_is_ssh_key" "ssh_key" {
  name = var.ssh_key_name
}

data "ibm_is_image" "ubuntu" {
  name = var.ubuntu1804[var.generation]
}

resource "ibm_is_instance" "vsi1" {
  name    = "${var.basename}-vsi1"
  vpc     = ibm_is_vpc.vpc.id
  zone    = var.ibm_zones[0]
  keys    = [data.ibm_is_ssh_key.ssh_key.id]
  image   = data.ibm_is_image.ubuntu.id
  profile = var.profile[var.generation]

  primary_network_interface {
    subnet = ibm_is_subnet.subnet1.id
    security_groups = local.ibm_vsi1_security_groups
  }

  user_data = local.ibm_vsi1_user_data
}

resource "ibm_is_floating_ip" "vsi1" {
  name   = "${var.basename}-vsi1"
  target = ibm_is_instance.vsi1.primary_network_interface[0].id
}

output "vpc_id" {
  value = ibm_is_vpc.vpc.id
}

output "ibm1_public_ip" {
  value = ibm_is_floating_ip.vsi1.address
}

output "ibm1_private_ip" {
  value = ibm_is_instance.vsi1.primary_network_interface[0].primary_ipv4_address
}

