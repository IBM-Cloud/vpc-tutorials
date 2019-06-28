provider "ibm" {
  region          = "us-south"
  ibmcloud_api_key = "${var.ibmcloud_api_key}"
  generation = 1
}
locals {
  BASENAME = "${var.prefix}vpc-pubpriv"
}
module vpc_pub_priv {
  source = "../../vpc-public-app-private-backend/tfmodule"
  basename = "${local.BASENAME}"
  ssh_key_name = "${var.ssh_key_name}"
  zone = "${var.zone}"
  backend_pgw = false
  profile = "${var.profile}"
  image_name = "${var.image_name}"
  maintenance = "${var.maintenance}"
  frontend_user_data = "${file("../shared/cloud-config.yaml")}"
  backend_user_data = "${file("../shared/cloud-config.yaml")}"
}

locals {
  bastion_ip = "${module.vpc_pub_priv.bastion_floating_ip_address}"
}
output "BASTION_IP_ADDRESS" {
  value = "${local.bastion_ip}"
}

locals {
  uploaded = "uploaded.sh"
}
# Frontend
resource "null_resource" "copy_from_on_prem" {
  connection {
    type        = "ssh"
    user        = "root"
    host        = "${module.vpc_pub_priv.frontend_network_interface_address}"
    private_key = "${file("~/.ssh/id_rsa")}"
    bastion_user        = "root"
    bastion_host        = "${local.bastion_ip}"
    bastion_private_key = "${file("~/.ssh/id_rsa")}"
  }
  provisioner "file" {
    source      = "../shared/${local.uploaded}"
    destination = "/${local.uploaded}"
  }
  provisioner "remote-exec" {
    inline      = [
      "bash -x /${local.uploaded}",
    ]
  }
}
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
resource "null_resource" "back_copy_from_on_prem" {
  connection {
    type        = "ssh"
    user        = "root"
    host        = "${module.vpc_pub_priv.backend_network_interface_address}"
    private_key = "${file("~/.ssh/id_rsa")}"
    bastion_user        = "root"
    bastion_host        = "${local.bastion_ip}"
    bastion_private_key = "${file("~/.ssh/id_rsa")}"
  }
  provisioner "file" {
    source      = "../shared/${local.uploaded}"
    destination = "/${local.uploaded}"
  }
  provisioner "remote-exec" {
    inline      = [
      "pwd > /pwd.txt",
      "bash -x /${local.uploaded}",
    ]
  }
}
output "sshbackend" {
  value = "ssh -o ProxyJump=root@${local.bastion_ip} root@${module.vpc_pub_priv.backend_network_interface_address}"
}
output "BACK_IP_ADDRESS" {
  value = "${module.vpc_pub_priv.backend_floating_ip_address}"
}
output "BACK_NIC_IP" {
  value = "${module.vpc_pub_priv.backend_network_interface_address}"
}
