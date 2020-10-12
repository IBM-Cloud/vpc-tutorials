variable "ibmcloud_api_key" {
  description = "You IAM based API key."
  default     = ""
}

variable "vpc_region" {
  description = "The VPC region to deploy the resources under."
  default     = ""
}

variable "vpc_ssh_key" {
  description = "The names of SSH key used to access virtual server instances after creation."
  default = ""
}

variable "resource_group" {
  description = "The resource group for all the resources created (VPC and non VPC)."
  default     = ""
}

variable "resources_prefix" {
  description = "Prefix is added to all resources that are created by this template."
  default     = "lamp"
}

variable "vpc_image_profile" {
  description = "The profile for admin instance, it does not require a lot of system resources."
  default     = "cx2-2x4"
}

variable "vpc_image_name" {
  description = "The scripts required for this configuration have only been validated on Ubuntu."
  default     = "ibm-ubuntu-18-04-1-minimal-amd64-2"
}

variable "TF_VERSION" {
  description = "terraform engine version to be used in schematics"
  default = "0.12"
}

variable "byok_data_volume" {
  description = "Indicates whether or not to create a BYOK data volume based on Key Protect, values can be true or false, default to false."
  default     = false
}