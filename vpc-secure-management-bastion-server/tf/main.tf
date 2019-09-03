provider "ibm" {
  region           = "${var.region}"
  ibmcloud_api_key = "${var.ibmcloud_api_key}"
  generation       = 1
  ibmcloud_timeout = "${var.ibmcloud_timeout}"
}

locals {
  BASENAME = "${var.prefix}vpc-pubpriv"
}

resource "ibm_is_vpc" "vpc" {
  name = "${local.BASENAME}"
}

resource "ibm_is_subnet" "bastion" {
  name                     = "${local.BASENAME}-bastion-subnet"
  vpc                      = "${ibm_is_vpc.vpc.id}"
  zone                     = "${var.zone}"
  total_ipv4_address_count = 256
}

data "ibm_is_image" "os" {
  name = "${var.image_name}"
}

data "ibm_is_ssh_key" "sshkey" {
  name = "${var.ssh_key_name}"
}

module bastion {
  source            = "../tfmodule"
  basename          = "${local.BASENAME}"
  ibm_is_vpc_id     = "${ibm_is_vpc.vpc.id}"
  zone              = "${var.zone}"
  remote            = "0.0.0.0/0"
  profile           = "${var.profile}"
  ibm_is_image_id   = "${data.ibm_is_image.os.id}"
  ibm_is_ssh_key_id = "${data.ibm_is_ssh_key.sshkey.id}"
  ibm_is_subnet_id  = "${ibm_is_subnet.bastion.id}"
}
