/*
Put the terraform variable TF_VAR_x to replace this value, for example:
$ env | grep TF
TF_VAR_ibmcloud_api_key=123456
*/
variable "ibmcloud_api_key" {
}

# 1 vpc generation classic, 2 vpc
variable "generation" {
  default = "2"
}

variable "ibmcloud_timeout" {
  description = "Timeout for API operations in seconds."
  default     = 900
}

/*
ssh key name the string 'pfq' in the example below:
$ ibmcloud is keys
Listing keys under account Powell Quiring's Account as user pquiring@us.ibm.com...
ID                                     Name   Type   Length   FingerPrint          Created
636f6d70-0000-0001-0000-00000014f113   pfq    rsa    4096     vaziuuZ4/BVQrgFO..   2 months ago
*/
variable "ssh_key_name" {
}

# resource group to use for the vpc and all resources
variable "resource_group_name" {
}

variable "prefix" {
  default = "tfapp01"
}

variable "region" {
  default = "us-south"
}

/*
zone string, us-south-1, in the example below
$ ibmcloud is zones
Listing zones in target region us-south under account Powell Quiring's Account as user pquiring@us.ibm.com...
Name         Region     Status   
us-south-3   us-south   available   
us-south-1   us-south   available   
us-south-2   us-south   available   
*/
variable "zone" {
  default = "us-south-1"
}

/*
instance profile string, cc1-2x4, in the example below
$ ibmcloud is instance-profiles
Listing server profiles under account Powell Quiring's Account as user pquiring@us.ibm.com...
Name         Family
...
cc1-2x4      cpu
*/

variable "profile" {
  default = "cc1-2x4"
}

/*
image name, centos-7.x-amd64, in the example below
$ ibmcloud is images
Listing images under account Powell Quiring's Account as user pquiring@us.ibm.com...
ID                                     Name                    OS                                                        Created        Status   Visibility
cc8debe0-1b30-6e37-2e13-744bfb2a0c11   centos-7.x-amd64        CentOS (7.x - Minimal Install)                            6 months ago   READY    public
cfdaf1a0-5350-4350-fcbc-97173b510843   ubuntu-18.04-amd64      Ubuntu Linux (18.04 LTS Bionic Beaver Minimal Install)    6 months ago   READY    public
...
*/
variable "image_name" {
  # default = "centos-7.x-amd64"
  default = "ubuntu-18.04-amd64"
}

# true keeps the maintenance security group on frontend and backend instances, allowing ssh access
variable "maintenance" {
  default = true
}

