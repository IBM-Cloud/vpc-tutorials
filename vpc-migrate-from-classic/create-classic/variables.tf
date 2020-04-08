variable "ibmcloud_api_key" {}

variable "iaas_classic_username" {}

variable "iaas_classic_api_key" {}

variable "ssh_public_key_file" {}

variable "ssh_private_key_file" {}

variable "classic_datacenter" {}

variable "region" {
  default = "us-south"
}

variable "prefix" {
  default = "migrate-example"
}
