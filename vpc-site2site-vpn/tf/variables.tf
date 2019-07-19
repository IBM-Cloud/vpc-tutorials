# see export.template for these:
variable ibmcloud_api_key {}

variable "softlayer_username" {}

variable "softlayer_api_key" {}

# ssh key name the string 'pfq' in the example below:
# $ ibmcloud is keys
# Listing keys under account Powell Quiring's Account as user pquiring@us.ibm.com...
# ID                                     Name   Type   Length   FingerPrint          Created
# 636f6d70-0000-0001-0000-00000014f113   pfq    rsa    4096     vaziuuZ4/BVQrgFO..   2 months ago
variable "ssh_key_name" {
  description = ""
}

variable "prefix" {
  description = "resources created will be named: ${prefix}vpc-pubpriv, vpc name will be ${prefix} or will be defined by vpc_name"
  default = "vpns2s"
}

# if this is empty use the basename for the vpc name.  If not empty then use this for the vpc_name
variable "vpc_name" {
  description = ""
  default = ""
}

variable "region" {
  description = ""
  default = "us-south"
}

# zone string, us-south-1, in the example below
# $ ibmcloud is zones
# Listing zones in target region us-south under account Powell Quiring's Account as user pquiring@us.ibm.com...
# Name         Region     Status   
# us-south-3   us-south   available   
# us-south-1   us-south   available   
# us-south-2   us-south   available   
variable "zone" {
  description = ""
  default = "us-south-1"
}

# set to true if the cloud should have a public gateway.  This is used to provision software.
variable "cloud_pgw" {
  description = ""
  default = true
}

# set to true if the bastion should have a public gateway.  This is used to provision software.
variable "bastion_pgw" {
  description = ""
  default = false
}

# instance profile string, cc1-2x4, in the example below
# $ ibmcloud is instance-profiles
# Listing server profiles under account Powell Quiring's Account as user pquiring@us.ibm.com...
# Name         Family
# ...
# cc1-2x4      cpu
variable "profile" {
  description = ""
  default = "cc1-2x4"
}

# image name, centos-7.x-amd64, in the example below
# $ ibmcloud is images
# Listing images under account Powell Quiring's Account as user pquiring@us.ibm.com...
# ID                                     Name                    OS                                                        Created        Status   Visibility
# cc8debe0-1b30-6e37-2e13-744bfb2a0c11   centos-7.x-amd64        CentOS (7.x - Minimal Install)                            6 months ago   READY    public
# cfdaf1a0-5350-4350-fcbc-97173b510843   ubuntu-18.04-amd64      Ubuntu Linux (18.04 LTS Bionic Beaver Minimal Install)    6 months ago   READY    public
# ...
variable "cloud_image_name" {
  description = "OS image used for the cloud and bastion vsi."
  default = "ubuntu-18.04-amd64"
}

# when true, the cloud instance will add the bastion maintenance security group
# to their security group list, allowing ssh access from the bastion
variable "maintenance" {
  description = ""
  default = true
}

variable "resource_group_name" {
  description = ""
}

variable "onprem_image_name" {
  description = ""
  default = "Ubuntu_latest"
}

variable "onprem_datacenter" {
  description = ""
  default = "dal10"
}

variable "onprem_ssh_key_name" {
  description = ""
}