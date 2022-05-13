# common place for cidr blocks.  resource group, image, ssh key common to both on prem and cloud

locals {
  BASENAME_ONPREM = "${var.prefix}-onprem"
  BASENAME_CLOUD  = "${var.prefix}-cloud"
  PRESHARED_KEY   = "20_PRESHARED_KEY_KEEP_SECRET_19"

  tags = [
    "prefix:${var.prefix}",
    lower(replace("dir:${abspath(path.root)}", "/", "_")),
  ]

  cidr_onprem        = "10.0.0.0/16"
  cidr_onprem_1      = "10.0.0.0/18" # zone 1 on prem, leave room for more zones in future
  cidr_onprem_subnet = "10.0.0.0/24"

  cidr_cloud         = "10.1.0.0/16"
  cidr_cloud_1       = "10.1.0.0/18" # zone 1 in cloud, leave room for more zones in future
  cidr_cloud_subnet  = "10.1.1.0/24"
  cidr_cloud_bastion = "10.1.0.0/24"

  cloud_image_name = "ibm-ubuntu-20-04-3-minimal-amd64-2"

}

data "ibm_resource_group" "all_rg" {
  name = var.resource_group_name
}

data "ibm_is_ssh_key" "sshkey" {
  name = var.ssh_key_name
}

data "ibm_is_image" "os" {
  name = local.cloud_image_name
}
