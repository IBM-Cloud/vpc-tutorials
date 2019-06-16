variable "basename" { } # string added to the front for all created resources
# create resources in this vpc id
variable ibm_is_vpc_id { }
# bastion instance is put in this subnet
variable ibm_is_subnet_id { }
# cidr block of the on premises computers that can access the bastion
variable remote { }

# the rest of these are documented in ../../vpc-public-app-private-backend/tfmodule/variables.tf
variable profile { }
variable zone { }
variable ibm_is_image_id { }
variable ibm_is_ssh_key_id { }