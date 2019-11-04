variable "ibmcloud_api_key" {}
variable "ssh_public_key_file" {}
variable "ssh_key_name" {}

provider "ibm" {
  ibmcloud_api_key = "${var.ibmcloud_api_key}"
  generation       = 1
}

resource "ibm_is_ssh_key" "key" {
  name = "${var.ssh_key_name}"
  public_key = "${file("${var.ssh_public_key_file}")}"
}
