variable "ibmcloud_api_key" {}

variable "vsi_image_names" {
  type = list(string)
}

variable "ssh_key_name" {}

variable "resource_group_name" {}

variable "prefix" {}

variable "region" {}

variable "subnet_zone" {}
