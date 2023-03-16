provider "ibm" {
  ibmcloud_api_key = var.ibmcloud_api_key
  region           = var.region
}

locals {
  vsi_image_names = { for index, name in var.vsi_image_names : index => name }
}


data "ibm_is_image" "ds_image" {
  for_each   = local.vsi_image_names
  name       = each.value
  visibility = "private"
}

data "ibm_is_ssh_key" "key" {
  name = var.ssh_key_name
}

data "ibm_resource_group" "group" {
  name = var.resource_group_name
}

resource "ibm_is_vpc" "vpc" {
  name           = var.prefix
  resource_group = data.ibm_resource_group.group.id
}

resource "ibm_is_subnet" "subnet" {
  name                     = "${var.prefix}-subnet"
  vpc                      = ibm_is_vpc.vpc.id
  zone                     = var.subnet_zone
  total_ipv4_address_count = 64
  resource_group           = data.ibm_resource_group.group.id
}

# todo
resource "ibm_is_instance" "instance" {
  for_each       = local.vsi_image_names
  name           = "${var.prefix}-${each.value}"
  image          = data.ibm_is_image.ds_image[each.key].id
  vpc            = ibm_is_vpc.vpc.id
  zone           = var.subnet_zone
  profile        = "cx2-2x4"
  keys           = [data.ibm_is_ssh_key.key.id]
  resource_group = data.ibm_resource_group.group.id
  primary_network_interface {
    subnet          = ibm_is_subnet.subnet.id
    security_groups = [ibm_is_security_group.group.id]
  }
  user_data = <<-EOS
    #!/bin/bash
    python3 -m http.server 80
  EOS
}

resource "ibm_is_floating_ip" "public_ip" {
  for_each       = local.vsi_image_names
  name           = "${var.prefix}-${each.value}"
  target         = ibm_is_instance.instance[each.key].primary_network_interface.0.id
  resource_group = data.ibm_resource_group.group.id
}

resource "ibm_is_security_group" "group" {
  name           = "${var.prefix}-group"
  resource_group = data.ibm_resource_group.group.id
  vpc            = ibm_is_vpc.vpc.id
}

resource "ibm_is_security_group_rule" "allow_http" {
  group     = ibm_is_security_group.group.id
  direction = "inbound"
  remote    = "0.0.0.0/0"

  tcp {
    port_min = 80
    port_max = 80
  }
}

resource "ibm_is_security_group_rule" "allow_ssh" {
  group     = ibm_is_security_group.group.id
  direction = "inbound"
  remote    = "0.0.0.0/0"

  tcp {
    port_min = 22
    port_max = 22
  }
}

resource "ibm_is_security_group_rule" "allow_ping" {
  group     = ibm_is_security_group.group.id
  direction = "inbound"
  remote    = "0.0.0.0/0"

  icmp {
    type = 8
  }
}

resource "ibm_is_security_group_rule" "allow_all" {
  group     = ibm_is_security_group.group.id
  direction = "outbound"
  remote    = "0.0.0.0/0"
}

/*
TODO rm
resource "ibm_is_security_group_network_interface_attachment" "add_to_group" {
  security_group    = ibm_is_security_group.group.id
  network_interface = ibm_is_instance.instance.primary_network_interface.0.id
}
*/

output "VPC_VSI_IP_ADDRESSES" {
  value = { for index, name in local.vsi_image_names : name => ibm_is_floating_ip.public_ip[index].address }
}
