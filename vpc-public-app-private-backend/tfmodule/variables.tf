# this module does not have defaults for anything but the port that the backend makes available to the frontend

# ssh key name the string 'pfq' in the example below:
# $ ibmcloud is keys
# Listing keys under account Powell Quiring's Account as user pquiring@us.ibm.com...
# ID                                     Name   Type   Length   FingerPrint          Created
# 636f6d70-0000-0001-0000-00000014f113   pfq    rsa    4096     vaziuuZ4/BVQrgFO..   2 months ago
variable "ssh_key_name" {
}

variable "basename" { # string added to the front for all created resources, except perhaps the vpc - see next variable
}

# if this is empty use the basename for the vpc name.  If not empty then use this for the vpc_name
variable "vpc_name" {
}

# zone string, us-south-1, in the example below
# $ ibmcloud is zones
# Listing zones in target region us-south under account Powell Quiring's Account as user pquiring@us.ibm.com...
# Name         Region     Status   
# us-south-3   us-south   available   
# us-south-1   us-south   available   
# us-south-2   us-south   available   
variable "zone" {
}

# instance profile string, cx2-2x4, in the example below
# $ ibmcloud is instance-profiles
# Listing server profiles under account Powell Quiring's Account as user pquiring@us.ibm.com...
# Name         Family
# ...
# cx2-2x4      cpu
variable "profile" {
}

# image ID, r006-4861e0a4-8d36-4462-b497-767351f1d371
# $ ibmcloud is images
# ID                                          Name                                                Status       Arch    OS name                              OS version                                               File size(GB)   Visibility   Owner type   Encryption   Resource group
# r006-9663dcb5-1a74-45c9-8b01-e44d4b584db7   ibm-ubuntu-20-04-5-minimal-amd64-2                  available    amd64   ubuntu-20-04-amd64                   20.04 LTS Focal Fossa Minimal Install                    1               public       provider     none         Default
# r006-4861e0a4-8d36-4462-b497-767351f1d371   ibm-ubuntu-22-04-1-minimal-amd64-3                  available    amd64   ubuntu-22-04-amd64                   22.04 LTS Jammy Jellyfish Minimal Install                1               public       provider     none         Default
# ...
variable "ibm_is_image_id" {
}

# set to true if the backend should have a public gateway.  This is used to provision software.
variable "backend_pgw" {
}

# when true, both the frontend and backend instances will add the bastion maintenance security group
# to their security group list, allowing ssh access from the bastion
variable "maintenance" {
}

# provide the cloud-init script, empty means none
variable "frontend_user_data" {
}

variable "backend_user_data" {
}

# the backend security group allows ingress from the frontend for this port
# The frontend security group allows egress to the backend for this port
variable "backend_tcp_port" {
  default = 80
}

variable "resource_group_name" {
}

