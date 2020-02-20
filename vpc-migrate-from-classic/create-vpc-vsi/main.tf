provider "ibm" {
  ibmcloud_api_key = "${var.ibmcloud_api_key}"
  region           = "${var.region}"
  ibmcloud_timeout = "${var.ibmcloud_timeout}"
  generation       = "${var.generation}"
}

module map_gen1_to_gen2 {
  generation       = "${var.generation}"
  source = "../../tfshared/map-gen1-to-gen2/"
  image = "centos-7.x-amd64"
  profile = "cc1-2x4"
}
data "ibm_is_image" "ds_image" {
  name = "${var.vsi_image_name}"
}

data "ibm_is_ssh_key" "key" {
  name = "${var.ssh_key_name}"
}

data "ibm_resource_group" "group" {
  name = "${var.resource_group_name}"
}

resource "ibm_is_vpc" "vpc" {
  name           = "${var.prefix}-vpc"
  resource_group = "${data.ibm_resource_group.group.id}"
}

resource "ibm_is_subnet" "subnet" {
  name                     = "${var.prefix}-subnet"
  vpc                      = "${ibm_is_vpc.vpc.id}"
  zone                     = "${var.subnet_zone}"
  total_ipv4_address_count = 64
  resource_group           = "${data.ibm_resource_group.group.id}"
}

resource "ibm_is_instance" "instance" {
  name           = "${var.prefix}-instance"
  vpc            = "${ibm_is_vpc.vpc.id}"
  zone           = "${var.subnet_zone}"
  profile        = "${module.map_gen1_to_gen2.profile}"
  image          = "${data.ibm_is_image.ds_image.id}"
  keys           = ["${data.ibm_is_ssh_key.key.id}"]
  resource_group = "${data.ibm_resource_group.group.id}"

  primary_network_interface = {
    subnet = "${ibm_is_subnet.subnet.id}"
  }
}

resource "ibm_is_floating_ip" "public_ip" {
  name           = "${var.prefix}-public-ip"
  target         = "${ibm_is_instance.instance.primary_network_interface.0.id}"
  resource_group = "${data.ibm_resource_group.group.id}"
}

resource "ibm_is_security_group" "group" {
  name           = "${var.prefix}-group"
  resource_group = "${data.ibm_resource_group.group.id}"
  vpc            = "${ibm_is_vpc.vpc.id}"
}

resource "ibm_is_security_group_rule" "allow_http" {
  group     = "${ibm_is_security_group.group.id}"
  direction = "inbound"
  remote    = "0.0.0.0/0"

  tcp = {
    port_min = 80
    port_max = 80
  }
}

resource "ibm_is_security_group_rule" "allow_ssh" {
  group     = "${ibm_is_security_group.group.id}"
  direction = "inbound"
  remote    = "0.0.0.0/0"

  tcp = {
    port_min = 22
    port_max = 22
  }
}

resource "ibm_is_security_group_rule" "allow_ping" {
  group     = "${ibm_is_security_group.group.id}"
  direction = "inbound"
  remote    = "0.0.0.0/0"

  icmp = {
    type = 8
  }
}

resource "ibm_is_security_group_rule" "allow_all" {
  group     = "${ibm_is_security_group.group.id}"
  direction = "outbound"
  remote    = "0.0.0.0/0"
}

resource "ibm_is_security_group_network_interface_attachment" "add_to_group" {
  security_group    = "${ibm_is_security_group.group.id}"
  network_interface = "${ibm_is_instance.instance.primary_network_interface.0.id}"
}

output "VPC_VSI_IP_ADDRESS" {
  value = "${ibm_is_floating_ip.public_ip.address}"
}
