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

# instance profile string, cc1-2x4, in the example below
# $ ibmcloud is instance-profiles
# Listing server profiles under account Powell Quiring's Account as user pquiring@us.ibm.com...
# Name         Family
# ...
# cc1-2x4      cpu
variable "profile" {
}

# image ID, cc8debe0-1b30-6e37-2e13-744bfb2a0c11, in the example below
# $ ibmcloud is images
# Listing images under account Powell Quiring's Account as user pquiring@us.ibm.com...
# ID                                     Name                    OS                                                        Created        Status   Visibility
# cc8debe0-1b30-6e37-2e13-744bfb2a0c11   centos-7.x-amd64        CentOS (7.x - Minimal Install)                            6 months ago   READY    public
# cfdaf1a0-5350-4350-fcbc-97173b510843   ubuntu-18.04-amd64      Ubuntu Linux (18.04 LTS Bionic Beaver Minimal Install)    6 months ago   READY    public
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

