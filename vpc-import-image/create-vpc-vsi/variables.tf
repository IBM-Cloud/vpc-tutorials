variable "ibmcloud_api_key" {}

variable "vsi_image_name" {}

variable "ssh_key_name" {}

variable "resource_group_name" {}

variable "prefix" {
  default = "migrate-example"
}

variable "region" {
  default = "us-south"
}

variable "subnet_zone" {}
