variable "ibmcloud_api_key" {
  description = "Your IBM Cloud IAM API key"
  default     = ""
}

variable "ibmcloud_timeout" {
  description = "Timeout for API operations in seconds."
  default     = 900
}

variable "resource_group_name" {
  description = "Your resource group name"
  default     = ""
}

variable "vpc_name" {
  description = "Unique name to your VPC"
}

variable "basename" {
  description = "Prefix used for all resource names"
}

variable "region" {
  description = "The region in which you want to provision your VPC and its resources"
  default     = "us-south"
}

variable "ssh_keyname" {
  description = "Name of the SSH key to use"
}

variable "certificate_crn" {
  description = "certificate instance CRN if you wish SSL offloading or End-to-end encryption"
  type        = string
  default     = ""
}

variable "enable_end_to_end_encryption" {
  description = "Set it to true if you wish to enable End-to-end encryption"
  type        = bool
  default     = false
}