# Shared
variable "basename" {
  description = "Name for the VPCs to create and prefix to use for all other resources."
  default     = "aaa"
}


variable "generation" {
  default = "2" # either "1" or "2"
}

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

variable "ubuntu1804" {
  default = {
    "1" = "ubuntu-18.04-amd64"
    "2" = "ibm-ubuntu-18-04-64"
  }
}

variable "profile" {
  default = {
    "1" = "cc1-2x4"
    "2" = "cx2-2x4"
  }
}

