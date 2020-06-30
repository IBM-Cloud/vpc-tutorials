variable "ibmcloud_api_key" {
  description = "You IAM based API key."
}

variable "vpc_region" {
  description = "The VPC region to deploy the resources under."
}

variable "vpc_ssh_key" {
  description = "The names of SSH key used to access virtual server instances after creation."
  default = ""
}

variable "resource_group" {
  description = "The resource group for all the resources created (VPC and non VPC)."
  default     = ""
}

variable "ssh_private_key_format" {
  description = "Indicates if the ssh_private_key value provided is the file system location or the content of the private ssh key. Values can be file or content."
  default     = "file"
}

variable "ssh_private_key" {
  description = "The file system location of private ssh key for virtual server instances access. It needs to be a local file."
  default     = ""
}

variable "resources_prefix" {
  description = "Prefix is added to all resources that are created by this template."
  default     = "lamp"
}

variable "generation" {
  description = "The VPC generation, currently supports Gen 1. Gen 2 tested in Beta."
  default     = 2
}

variable "vpc_image_profile" {
  description = "The profile for admin instance, it does not require a lot of system resources."
  default     = "cx2-2x4"
}

variable "vpc_image_name" {
  description = "The scripts required for this configuration have only been validated on Ubuntu."
  default     = "ibm-ubuntu-18-04-1-minimal-amd64-2"
}


variable "null" {
  default = ""
}

variable "TF_VERSION" {
  default = "0.12"
  description = "terraform engine version to be used in schematics"
}

variable "byok_data_volume" {
  description = "Indicates whether or not to create a BYOK data volume based on Key Protect, values can be true or false, default to false."
  default     = false
}

variable "config_script" {
  description = "Shell script to run first time the server is started, it needs to reside in the scripts folder."
  default = "lamp-manual.sh"
}
