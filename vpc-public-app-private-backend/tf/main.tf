provider "ibm" {
  region          = "us-south"
  ibmcloud_api_key = "${var.ibmcloud_api_key}"
  generation = 1 
}
locals {
  BASENAME = "${var.prefix}vpc-pubpriv"
}
module vpc_pub_priv {
  source = "../tfmodule"
  basename = "${local.BASENAME}"
  ssh_key_name = "${var.ssh_key_name}"
  zone = "${var.zone}"
  backend_pgw = "${var.backend_pgw}"
  profile = "${var.profile}"
  image_name = "${var.image_name}"
  maintenance = "${var.maintenance}"
  frontend_user_data = ""
  backend_user_data = ""
}
locals {
  bastion_ip = "${module.vpc_pub_priv.bastion_floating_ip_address}"
}
output "sshbastion" {
  value = "ssh root@${local.bastion_ip}"
}
output "sshfrontend" {
  value = "ssh -o ProxyJump=root@${local.bastion_ip} root@${module.vpc_pub_priv.frontend_network_interface_address}"
}
