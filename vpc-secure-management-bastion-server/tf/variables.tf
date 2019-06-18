# see export.template for these:
variable ibmcloud_api_key { }
variable "ssh_key_name" { }

# resources created will be named: ${prefix}vpc-pubpriv
variable "prefix" {
  default = "tfb"
}

# These variables are well documented in the ../../vpc-public-app-private-backend//tfmodule/variable.tf file.
variable "zone" {
  default = "us-south-1"
}
variable "profile" {
  default = "cc1-2x4"
}
variable "image_name" {
  default = "centos-7.x-amd64"
}
