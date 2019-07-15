output "vpc_vsi_bastion_fip" {
  value = "${ibm_is_floating_ip.vpc_vsi_bastion_fip.0.address}"
}

output sg_maintenance_id {
    value = "${ibm_is_security_group.sg_maintenance.id}"
}