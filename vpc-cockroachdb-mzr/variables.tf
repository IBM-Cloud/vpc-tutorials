variable "ibmcloud_api_key" {
  description = "You IAM based API key."
}

variable "vpc_region" {
  description = "The VPC region to deploy the resources under."
}

variable "vpc_ssh_keys" {
  type        = list(string)
  description = "The names of SSH keys used to access virtual server instances after creation. They need to be commma separated and inside double quotes."
  default = [""]
}

variable "resource_group" {
  description = "The resource group for all the resources created (VPC and non VPC)."
  default     = ""
}

variable "ssh_private_key_format" {
  description = "Indicates if the ssh_private_key value provided is the file system location or the content of the private ssh key. Values can me file or content."
  default     = "file"
}

variable "ssh_private_key" {
  description = "The file system location of private ssh key for virtual server instances access. It needs to be a local file."
  default     = ""
}

variable "resources_prefix" {
  description = "Prefix is added to all resources that are created by this template."
  default     = "cockroach"
}

variable "generation" {
  description = "The VPC generation, currently supports Gen 1. Gen 2 tested in Beta."
  default     = 1
}

variable "vpc_database_image_profile" {
  description = "The profile for the database instance, increase the size based on environment need."
  default     = "cc1-2x4"
}

variable "vpc_app_image_profile" {
  description = "The profile for the application instance, increase the size based on environment need"
  default     = "cc1-2x4"
}

variable "vpc_admin_image_profile" {
  description = "The profile for admin instance, it does not require a lot of system resources."
  default     = "cc1-2x4"
}

variable "vpc_admin_image_name" {
  description = "The scripts required for this configuration have only been validated on Ubuntu."
  default     = "ubuntu-18.04-amd64"
}

variable "vpc_app_image_name" {
  description = "The scripts required for this configuration have only been validated on Ubuntu."
  default     = "ubuntu-18.04-amd64"
}

variable "vpc_database_image_name" {
  description = "The scripts required for this configuration have only been validated on Ubuntu."
  default     = "ubuntu-18.04-amd64"
}

variable "null" {
  default = ""
}

variable "vpc_zones" {
  description = "The availability zone list for the VPC regions."

  default = {
    au-syd-availability-zone-1   = "au-syd-1"
    au-syd-availability-zone-2   = "au-syd-2"
    au-syd-availability-zone-3   = "au-syd-3"
    eu-de-availability-zone-1    = "eu-de-1"
    eu-de-availability-zone-2    = "eu-de-2"
    eu-de-availability-zone-3    = "eu-de-3"
    eu-gb-availability-zone-1    = "eu-gb-1"
    eu-gb-availability-zone-2    = "eu-gb-2"
    eu-gb-availability-zone-3    = "eu-gb-3"
    jp-tok-availability-zone-1   = "jp-tok-1"
    jp-tok-availability-zone-2   = "jp-tok-2"
    jp-tok-availability-zone-3   = "jp-tok-3"
    us-south-availability-zone-1 = "us-south-1"
    us-south-availability-zone-2 = "us-south-2"
    us-south-availability-zone-3 = "us-south-3"
  }
}

