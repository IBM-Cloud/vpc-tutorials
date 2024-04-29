# see export.template for these:
variable "ibmcloud_api_key" {
}

variable "ssh_key_name" {
}

variable "ibmcloud_timeout" {
  description = "Timeout for API operations in seconds."
  default     = 900
}

# resources created will be named: ${prefix}vpc-pubpriv, vpc name will be ${prefix} or will be defined by vpc_name
variable "prefix" {
  default = "tf00"
}

# if this is empty use the basename for the vpc name.  If not empty then use this for the vpc_name
variable "vpc_name" {
  default = ""
}

# These variables are well documented in the ../tfmodule/variable.tf file.
variable "region" {
  default = "us-south"
}

variable "zone" {
  default = "us-south-1"
}

variable "backend_pgw" {
  default = false
}

variable "profile" {
  default = "cx2-2x4"
}

variable "image_name" {
  default = "ibm-ubuntu-22-04-1-minimal-amd64-4"
}

variable "maintenance" {
  default = true
}

##
variable "resource_group_name" {
}

