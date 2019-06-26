# see ../export.template for ibmcloud_api_key and ssh_key_name
variable ibmcloud_api_key { }
variable "ssh_key_name" { }

variable "prefix" {
  default = "tfansible"
}

# These are defined in ../../../vpc-public-app-private-backend/tfmodule/variables.tf
variable "zone" {
  default = "us-south-1"
}
variable "profile" {
  default = "cc1-2x4"
}
variable "image_name" {
  # default = "centos-7.x-amd64"
  default = "ubuntu-18.04-amd64"
}
variable maintenance {
  default = true
}
