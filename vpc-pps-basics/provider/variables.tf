variable "region" {
  default = "us-south"
  description = "Region where to create resources."
}

variable "basename" {
  default = "vpc-pps"
  description = "Prefix to use when naming resources. Use only letters and hyphens."
}

variable "tags" {
  default = ["terraform", "pps", "provider"]
}

variable "existing_resource_group_name" {
  default = ""
  description = "Name of an existing resource group where the resources will be created. Leave it empty to create a new resource group."
}

variable "existing_ssh_key_name" {
  description = "Name of an existing VPC SSH key to inject in virtual server instances."
}

variable "create_floating_ips" {
  default = false
  description = "Used for debug only. When set to true, floating IPs will be assigned to all virtual servers."
}

variable "instance_profile" {
  default = "cx2-2x4"
  description = "Profile used by virtual server instances."
}
