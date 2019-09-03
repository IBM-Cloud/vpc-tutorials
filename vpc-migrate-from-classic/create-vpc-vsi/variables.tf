variable "ibmcloud_api_key" {}

variable "vsi_image_name" {}

variable "ssh_key_name" {}

variable "resource_group_name" {}

variable "prefix" {
  default = "migrate-example"
}

variable "subnet_zone" {}

variable "ibmcloud_timeout" {
  description = "Timeout for API operations in seconds."
  default     = 900
}
