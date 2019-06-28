# see export.template for these:
variable ibmcloud_api_key { }
variable "ssh_key_name" { }

# resources created will be named: ${prefix}vpc-pubpriv, vpc name will be ${prefix}
variable "prefix" {
  default = "tf00"
}

# These variables are well documented in the ../tfmodule/variable.tf file.
variable "zone" {
  default = "us-south-1"
}
variable "backend_pgw" {
  default = false
}
variable "profile" {
  default = "cc1-2x4"
}
variable "image_name" {
  default = "ubuntu-18.04-amd64"
}
variable "maintenance" {
  default = true
}

##
variable "resource_group_name" {
  default = "defaultRG"
}
