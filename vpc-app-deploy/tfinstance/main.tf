variable ibmcloud_api_key {}
variable ssh_key_name {}
variable resource_group_name {}

locals {
  BASENAME = "example"   # make this a unique vpc name, all resources will have this as a prefix
  SSH_KEY  = "pfq"        # create an ssh key in the cloud as a prerequisite step, see ???
  REGION   = "us-south"   # choose a supported region, see ???
  ZONE     = "us-south-1" # choose a supported zone, see ???
}


provider ibm {
  region           = "${local.REGION}"
  ibmcloud_api_key = "${var.ibmcloud_api_key}"
  generation       = 1                         # vpc on classic
}
data "ibm_resource_group" "group" {
  name = "${var.resource_group_name}"
}

resource ibm_is_vpc "vpc" {
  name = "${local.BASENAME}"
  resource_group = "${data.ibm_resource_group.group.id}"
}

resource ibm_is_security_group "sg1" {
  name = "${local.BASENAME}-sg1"
  vpc  = "${ibm_is_vpc.vpc.id}"
}

# allow ssh access to this instance from anywhere on the planet
resource "ibm_is_security_group_rule" "ingress_ssh_all" {
  group     = "${ibm_is_security_group.sg1.id}"
  direction = "ingress"
  remote    = "0.0.0.0/0"                       # TOO OPEN for production

  tcp = {
    port_min = 22
    port_max = 22
  }
}

resource ibm_is_subnet "subnet1" {
  name                     = "${local.BASENAME}-subnet1"
  vpc                      = "${ibm_is_vpc.vpc.id}"
  zone                     = "${local.ZONE}"
  total_ipv4_address_count = 256
}

data ibm_is_ssh_key "ssh_key" {
  name = "${var.ssh_key_name}"
}

data ibm_is_image "ubuntu" {
  name = "ubuntu-18.04-amd64"
}

resource ibm_is_instance "vsi1" {
  name    = "${local.BASENAME}-vsi1"
  vpc     = "${ibm_is_vpc.vpc.id}"
  zone    = "${local.ZONE}"
  keys    = ["${data.ibm_is_ssh_key.ssh_key.id}"]
  image   = "${data.ibm_is_image.ubuntu.id}"
  profile = "cc1-2x4"

  primary_network_interface = {
    subnet          = "${ibm_is_subnet.subnet1.id}"
    security_groups = ["${ibm_is_security_group.sg1.id}"]
  }
}

resource ibm_is_floating_ip "fip1" {
  name   = "${local.BASENAME}-fip1"
  target = "${ibm_is_instance.vsi1.primary_network_interface.0.id}"
}

output sshcommand {
  value = "ssh root@${ibm_is_floating_ip.fip1.address}"
}
