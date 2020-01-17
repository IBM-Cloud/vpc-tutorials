provider "ibm" {
  region           = var.region
  ibmcloud_api_key = var.ibmcloud_api_key
  generation       = var.generation
  ibmcloud_timeout = var.ibmcloud_timeout
}

locals {
  BASENAME = "${var.prefix}vpc-pubpriv"

  user_data_frontend = <<EOF
#!/bin/bash
apt-get update
apt-get install -y nginx
echo "I am the frontend server" > /var/www/html/index.html
service nginx start
EOF


  user_data_backend = <<EOF
#!/bin/bash
apt-get update
apt-get install -y nginx
echo "I am the backend server" > /var/www/html/index.html
service nginx start
EOF

}

module "map_gen1_to_gen2" {
  generation = var.generation
  source     = "../../tfshared/map-gen1-to-gen2/"
  image      = var.image_name
  profile    = var.profile
}

data "ibm_is_image" "os" {
  name = module.map_gen1_to_gen2.image
}

module "vpc_pub_priv" {
  source              = "../tfmodule"
  basename            = local.BASENAME
  vpc_name            = var.vpc_name
  resource_group_name = var.resource_group_name
  ssh_key_name        = var.ssh_key_name
  zone                = var.zone
  backend_pgw         = var.backend_pgw
  profile             = module.map_gen1_to_gen2.profile
  ibm_is_image_id     = data.ibm_is_image.os.id
  maintenance         = var.maintenance
  frontend_user_data  = local.user_data_frontend
  backend_user_data   = local.user_data_backend
}

locals {
  bastion_ip = module.vpc_pub_priv.bastion_floating_ip_address
}

output "BASTION_IP_ADDRESS" {
  value = local.bastion_ip
}

output "sshbastion" {
  value = "ssh root@${local.bastion_ip}"
}

output "sshfrontend" {
  value = "ssh -o ProxyJump=root@${local.bastion_ip} root@${module.vpc_pub_priv.frontend_network_interface_address}"
}

output "FRONT_IP_ADDRESS" {
  value = module.vpc_pub_priv.frontend_floating_ip_address
}

output "FRONT_NIC_IP" {
  value = module.vpc_pub_priv.frontend_network_interface_address
}

output "sshbackend" {
  value = "ssh -o ProxyJump=root@${local.bastion_ip} root@${module.vpc_pub_priv.backend_network_interface_address}"
}

output "BACK_IP_ADDRESS" {
  value = module.vpc_pub_priv.backend_floating_ip_address
}

output "BACK_NIC_IP" {
  value = module.vpc_pub_priv.backend_network_interface_address
}

