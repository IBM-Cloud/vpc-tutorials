variable "ibmcloud_api_key" {
  description = "You IAM based API key."
  default     = ""
}

variable "vpc_region" {
  description = "The VPC region to deploy the resources under."
  default     = "us-south"
}

variable "vpc_ssh_key" {
  description = "The names of SSH key used to access virtual server instances after creation."
  default     = ""
}

variable "resource_group" {
  description = "The resource group for all the resources created (VPC and non VPC)."
  default     = "default"
}

variable "ssh_private_key_file" {
  description = "The file system location of private ssh key for virtual server instances access, i.e ~/.ssh/id_rsa and it needs to be a local file."
  default     = ""
}

variable "ssh_private_key_content" {
  description = "The content of the private ssh key for virtual server instances access. Only use if the content of the private key is provided in the variable."
  default     = ""
}

variable "resources_prefix" {
  description = "Prefix is added to all resources that are created by this template."
  default     = "is"
}

variable "vpc_app_image_profile" {
  description = "The profile for the application instance, increase the size based on environment need"
  default     = "cx2d-4x8"
}

variable "vpc_app_image_name" {
  description = "The scripts required for this configuration have only been validated on Ubuntu."
  default     = "ibm-ubuntu-20-04-minimal-amd64-2"
}

variable "boot_volume_name" {
  description = "The name for the boot volume of the app vsi."
  default     = ""
}

variable "boot_volume_auto_delete" {
  description = "True or False to delete the boot volume on VSI delete."
  default     = true
}
