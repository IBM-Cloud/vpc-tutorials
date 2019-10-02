# Shared
variable "basename" {
  description = "Name for the VPCs to create and prefix to use for all other resources."
  default     = "aaa"
}

# IBM
variable ibmcloud_api_key {}
variable ssh_key_name {}
variable ibm_region {
  default = "us-south"
}

variable ibm_zones {
  default = [
    "us-south-1",
    "us-south-2",
    "us-south-3",
  ]
}

# AWS
variable aws_region {
  default = "us-west-2"
}

variable aws_zones {
  default = [
    "us-west-2a",
    "us-west-2b",
    "us-west-2c",
  ]
}
variable aws_ssh_key_name {
  default = "pfq"
}
variable aws_access_key_id {}
variable aws_secret_access_key {}


