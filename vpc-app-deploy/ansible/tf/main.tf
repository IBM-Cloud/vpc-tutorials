# copied from ../../tf/main.tf, then removed the software installation
provider "ibm" {
  region           = var.region
  ibmcloud_api_key = var.ibmcloud_api_key
  ibmcloud_timeout = var.ibmcloud_timeout
}

locals {
  BASENAME = "${var.prefix}ansvpc-pubpriv"
}

data "ibm_is_image" "os" {
  name = var.image_name
}

module "vpc_pub_priv" {
  source       = "../../../vpc-public-app-private-backend/tfmodule"
  basename     = local.BASENAME
  vpc_name     = local.BASENAME
  ssh_key_name = var.ssh_key_name
  zone         = var.zone

  # a public gateway can be connected to the backend subnet.
  # The frontend has a floating ip connected which provides both
  # a public IP and gateway to the internet.
  # This is going to allow open internet access for software installation.
  # The backend does not have access to the internet unless backend_pgw is true.
  backend_pgw = false

  profile             = var.profile
  ibm_is_image_id     = data.ibm_is_image.os.id
  resource_group_name = var.resource_group_name
  maintenance         = var.maintenance
  frontend_user_data  = ""
  backend_user_data   = ""
}

locals {
  bastion_ip = module.vpc_pub_priv.bastion_floating_ip_address
}

output "BASTION_IP_ADDRESS" {
  value = local.bastion_ip
}

locals {
  uploaded = "uploaded.sh"
}

/*----------------------------------------------------------------------
# Frontend
resource "null_resource" "copy_from_on_prem" {
  connection {
    type                = "ssh"
    user                = "root"
    host                = "${module.vpc_pub_priv.frontend_network_interface_address}"
    private_key         = "${file("~/.ssh/id_rsa")}"
    bastion_user        = "root"
    bastion_host        = "${local.bastion_ip}"
    bastion_private_key = "${file("~/.ssh/id_rsa")}"
  }

  provisioner "file" {
    source      = "../shared/${local.uploaded}"
    destination = "/${local.uploaded}"
  }

  provisioner "remote-exec" {
    inline = [
      "bash -x /${local.uploaded}",
    ]
  }
}
----------------------------------------------------------------------*/

output "sshfrontend" {
  value = "ssh -o ProxyJump=root@${local.bastion_ip} root@${module.vpc_pub_priv.frontend_network_interface_address}"
}

output "FRONT_IP_ADDRESS" {
  value = module.vpc_pub_priv.frontend_floating_ip_address
}

output "FRONT_NIC_IP" {
  value = module.vpc_pub_priv.frontend_network_interface_address
}

# Backend
/*----------------------------------------------------------------------
resource "null_resource" "back_copy_from_on_prem" {
  connection {
    type                = "ssh"
    user                = "root"
    host                = "${module.vpc_pub_priv.backend_network_interface_address}"
    private_key         = "${file("~/.ssh/id_rsa")}"
    bastion_user        = "root"
    bastion_host        = "${local.bastion_ip}"
    bastion_private_key = "${file("~/.ssh/id_rsa")}"
  }

  provisioner "file" {
    source      = "../shared/${local.uploaded}"
    destination = "/${local.uploaded}"
  }

  provisioner "remote-exec" {
    inline = [
      "pwd > /pwd.txt",
      "bash -x /${local.uploaded}",
    ]
  }
}
----------------------------------------------------------------------*/

output "sshbackend" {
  value = "ssh -o ProxyJump=root@${local.bastion_ip} root@${module.vpc_pub_priv.backend_network_interface_address}"
}

output "BACK_IP_ADDRESS" {
  value = module.vpc_pub_priv.backend_floating_ip_address
}

output "BACK_NIC_IP" {
  value = module.vpc_pub_priv.backend_network_interface_address
}
