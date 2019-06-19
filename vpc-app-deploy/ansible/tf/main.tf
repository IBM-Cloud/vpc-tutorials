# copied from ../../tf/main.tf, then removed the software installation
provider "ibm" {
  region          = "us-south"
  ibmcloud_api_key = "${var.ibmcloud_api_key}"
  generation = 1
}
locals {
  BASENAME = "${var.prefix}vpc-pubpriv"
}
module vpc_pub_priv {
  source = "../../../vpc-public-app-private-backend/tfmodule"
  basename = "${local.BASENAME}"
  ssh_key_name = "${var.ssh_key_name}"
  zone = "${var.zone}"
  backend_pgw = false
  profile = "${var.profile}"
  image_name = "${var.image_name}"
  maintenance = "${var.maintenance}"
  frontend_user_data = "" # no software
  backend_user_data = "" # no software
}

locals {
  bastion_ip = "${module.vpc_pub_priv.bastion_floating_ip_address}"
}
output "BASTION_IP_ADDRESS" {
  value = "${local.bastion_ip}"
}
# Frontend
output "sshfrontend" {
  value = "ssh -o ProxyJump=root@${local.bastion_ip} root@${module.vpc_pub_priv.frontend_network_interface_address}"
}
output "FRONT_IP_ADDRESS" {
  value = "${module.vpc_pub_priv.frontend_floating_ip_address}"
}
output "FRONT_NIC_IP" {
  value = "${module.vpc_pub_priv.frontend_network_interface_address}"
}
# Backend
output "sshbackend" {
  value = "ssh -o ProxyJump=root@${local.bastion_ip} root@${module.vpc_pub_priv.backend_network_interface_address}"
}
output "BACK_IP_ADDRESS" {
  value = "${module.vpc_pub_priv.backend_floating_ip_address}"
}
output "BACK_NIC_IP" {
  value = "${module.vpc_pub_priv.backend_network_interface_address}"
}
