# Shared
variable "basename" {
  description = "Name for the VPCs to create and prefix to use for all other resources."
  default     = "aaa"
}

variable "ibmcloud_api_key" { # /DELETE_ON_PUBLISH/d
}                             # /DELETE_ON_PUBLISH/d

variable "ssh_key_name" {
}

variable "ibm_region" {
  default = "us-south"
}

variable "ibm_zones" {
  default = [
    "us-south-1",
    "us-south-2",
    "us-south-3",
  ]
}

variable "ubuntu" {
  default = "ibm-ubuntu-22-04-1-minimal-amd64-3"
}

variable "profile" {
  default = "cx2-2x4"
}

