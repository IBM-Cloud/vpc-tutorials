module "vpc_bastion" {
  source = "./modules/vpc_bastion_tf"

  vpc_id                              = "${ibm_is_vpc.vpc.id}"
  vpc_resource_group_id               = "${data.ibm_resource_group.group.id}"
  vpc_public_gateway_id               = "${ibm_is_public_gateway.pgw.0.id}"

  vpc_ssh_keys                        = "${var.vpc_ssh_keys}"
  vpc_region                          = "${var.vpc_region}"
  vpc_zones                           = "${var.vpc_zones}"
  vpc_vsi_image_profile               = "${var.vpc_image_profile}"
  vpc_vsi_image_name                  = "${var.vpc_image_name}"
  
  vpc_vsi_name                        = "${var.resources_prefix}-bastion-vsi"
  vpc_vsi_security_group_name         = "${var.resources_prefix}-bastion-sg"
  vpc_subnet_name                     = "${var.resources_prefix}-bastion-subnet"
  vpc_vsi_fip_name                    = "${var.resources_prefix}-bastion-fip"
  vpc_maintenance_security_group_name = "${var.resources_prefix}-maintenance-sg"
}
