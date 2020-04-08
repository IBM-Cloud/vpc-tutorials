variable "ibmcloud_api_key" {
  description = "The IBM Cloud platform API key. The key is required to provision the cloud and bastion virtual server instances in the IBM Virtual Private Cloud."
}

variable "iaas_classic_username" {
  description = "The IBM Cloud infrastructure (SoftLayer) user name. Required to provision the onprem virtual server instance in the IBM Cloud Classic environment."
}

variable "iaas_classic_api_key" {
  description = "The IBM Cloud infrastructure API key. Required to provision the onprem virtual server instance in the IBM Cloud Classic environment."
}

variable "ibmcloud_timeout" {
  description = "Timeout for API operations in seconds."
  default     = 900
}

# 1 vpc generation classic, 2 vpc
variable "generation" {
  default = "1"
}

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

variable "vpc_name" {
  description = "if this is empty use the basename for the vpc name.  If not empty then use this for the vpc_name"
  default     = ""
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
  default     = "cc1-2x4"
}

variable "cloud_image_name" {
  description = "OS image used for the cloud and bastion vsi. To see a list of available images you can run the ibmcloud cli command: ibmcloud is images."
  default     = "ubuntu-18.04-amd64"
}

variable "maintenance" {
  description = "when true, the cloud instance will add the bastion maintenance security group to their security group list, allowing ssh access from the bastion."
  default     = true
}

variable "onprem_image_name" {
  description = "OS image used for the cloud and bastion vsi. To see a list of available images you can run the ibmcloud cli command: ibmcloud sl image list."
  default     = "Ubuntu_latest"
}

variable "onprem_datacenter" {
  description = "IBM Cloud data center that will host the simulated virtual server instance"
  default     = "dal10"
}

variable "onprem_ssh_key_name" {
  description = "SSH keys allow access to an instance without using a password, the tutorial requires one. Add one here: https://cloud.ibm.com/classic/devices/sshkeys."
}

