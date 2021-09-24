variable "ibmcloud_api_key" {
  description = "IBM API key. Refer https://cloud.ibm.com/docs/account?topic=account-userapikey&interface=ui"
}

variable "resource_group_name" {
  description = "Resource group name."
}

variable "vpc_name" {
  description = "Unique name for the VPC."
}

variable "basename" {
  description = "Prefix used for all resource names"
}

variable "ssh_keyname" {
  description = "SSH key name for VPC. Refer https://cloud.ibm.com/vpc-ext/compute/sshKeys"
}

variable "ibmcloud_timeout" {
  description = "Timeout for API operations in seconds."
  default     = 900
}

variable "region" {
  default     = "us-south"
  description = "For supported regions, refer https://cloud.ibm.com/docs/overview?topic=overview-locations"
}

variable "subnet_zone" {
  default     = "us-south-1"
  description = "For supported zones, refer https://cloud.ibm.com/docs/overview?topic=overview-locations"
}

variable "vsi_image_name" {
  default     = "ibm-ubuntu-20-04-2-minimal-amd64-1"
  description = "Ubuntu 20.04 images only"
}