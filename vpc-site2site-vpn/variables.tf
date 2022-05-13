# variables - see template.local.env for the required variables

variable "resource_group_name" {
  description = "Resource group that will contain all the resources created by the script."
}

variable "ssh_key_name" {
  description = "SSH keys are needed to connect to virtual instances. https://cloud.ibm.com/docs/vpc-on-classic?topic=vpc-on-classic-getting-started#prerequisites "
}

variable "prefix" {
  description = "resources created will be named: $${prefix}vpc-pubpriv, vpc name will be $${prefix} or will be defined by vpc_name"
  default     = "vpns2s"
}

variable "region" {
  description = "Availability zone that will have the resources deployed to.  To obtain a list of availability zones you can run the ibmcloud cli: ibmcloud is regions."
  default     = "us-south"
}

variable "zone" {
  description = "Availability zone that will have the resources deployed to.  To obtain a list of availability zones you can run the ibmcloud cli: ibmcloud is zones."
  default     = "us-south-1"
}

variable "cloud_pgw" {
  description = "set to true if the cloud should have a public gateway.  This is used to provision software."
  default     = true
}

variable "bastion_pgw" {
  description = "set to true if the bastion should have a public gateway.  This is used to provision software."
  default     = false
}

variable "profile" {
  description = "Indicates the compute resources assigned to the instance. To see a list of available options you can run the ibmcloud cli: ibmcloud is instance-profiles."
  default     = "cx2-2x4"
}

variable "maintenance" {
  description = "when true, the cloud instance will add the bastion maintenance security group to their security group list, allowing ssh access from the bastion."
  default     = true
}