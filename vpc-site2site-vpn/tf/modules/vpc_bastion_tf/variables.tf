# variable "ibmcloud_api_key" {}

variable "vpc_ssh_keys" {
  description = "ssh keys used to access virtual server instances after creation."
  default = []
}

variable "vpc_region" {
  description = "."

}

variable "vpc_zones" {
  description = "."
  default = {}
}

variable "vpc_vsi_image_profile" {
  description = "."

}
variable "vpc_vsi_image_name" {
  description = "."
}

variable "vpc_vsi_security_group_name" {
  description = "."
}

variable "vpc_maintenance_security_group_name" {
  description = "."
}
variable "vpc_vsi_name" {
  description = "."
}

variable "vpc_id" {
  description = "."
}

variable "vpc_resource_group_id" {
  description = "."
}

variable "vpc_subnet_name" {
  description = "."
}

variable "vpc_vsi_fip_name" {
  description = "."
}

variable "vpc_public_gateway_id" {
  description = "."
}
