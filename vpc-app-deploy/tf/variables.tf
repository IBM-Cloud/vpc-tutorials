/*
Put the terraform variable TF_VAR_x to replace this value, for example:
$ env | grep TF
TF_VAR_ibmcloud_api_key=123456
*/
variable "ibmcloud_api_key" {
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
instance profile string, cx2-2x4, in the example below
$ ibmcloud is instance-profiles
Listing server profiles under account Powell Quiring's Account as user pquiring@us.ibm.com...
Name         Family
...
cx2-2x4      cpu
*/

variable "profile" {
  default = "cx2-2x4"
}

/*
$ ibmcloud is images
ID                                          Name                                                Status       Arch    OS name                              OS version                                               File size(GB)   Visibility   Owner type   Encryption   Resource group
r006-9663dcb5-1a74-45c9-8b01-e44d4b584db7   ibm-ubuntu-20-04-5-minimal-amd64-2                  available    amd64   ubuntu-20-04-amd64                   20.04 LTS Focal Fossa Minimal Install                    1               public       provider     none         Default
r006-4861e0a4-8d36-4462-b497-767351f1d371   ibm-ubuntu-22-04-1-minimal-amd64-3                  available    amd64   ubuntu-22-04-amd64                   22.04 LTS Jammy Jellyfish Minimal Install                1               public       provider     none         Default
...
*/
variable "image_name" {
  default = "ibm-ubuntu-22-04-1-minimal-amd64-3"
}

# true keeps the maintenance security group on frontend and backend instances, allowing ssh access
variable "maintenance" {
  default = true
}

