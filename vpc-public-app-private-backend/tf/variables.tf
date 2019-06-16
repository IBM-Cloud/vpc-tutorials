# see export.template for these:
variable bluemix_api_key { }
variable "ssh_key_name" { }

# resources created will be named: ${prefix}vpc-pubpriv
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
  default = "centos-7.x-amd64"
}
variable "maintenance" {
  default = true
}