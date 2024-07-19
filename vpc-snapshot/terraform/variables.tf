variable "prefix" {}
variable "ibmcloud_api_key" {}
variable "region" {}
variable "resource_group_name" {}
variable "vpc_ssh_key_name" {}
variable "instance_image_name" {
  default = "ibm-ubuntu-20-04-minimal-amd64-2"
}
variable "profile" {
  default = "cx2-2x4"
}
