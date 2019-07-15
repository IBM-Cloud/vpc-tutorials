output "for reference" {
  value = <<REF
  
  - BASTION_IP_ADDRESS: ${module.vpc_bastion.vpc_vsi_bastion_fip}
  - VSI_CLOUD_IP: ${element(ibm_is_instance.vsi_cloud.*.primary_network_interface.0.primary_ipv4_address, 0)}
  - CLOUD_CIDR: ${ibm_is_subnet.sub_cloud.ipv4_cidr_block}
  - VSI_ONPREM_IP: ${ibm_compute_vm_instance.onprem_vsi.ipv4_address}
  - ONPREM_CIDR: ${ibm_compute_vm_instance.onprem_vsi.private_subnet}
  -
    REF
}

output "on_cloud_instances_access" {
  value = <<CLOUD

  ### You can access the app instance ${element(ibm_is_instance.vsi_cloud.*.name, 0)} using the following SSH command:###
    ssh -F scripts/ssh.config -J root@${module.vpc_bastion.vpc_vsi_bastion_fip} root@${element(ibm_is_instance.vsi_cloud.*.primary_network_interface.0.primary_ipv4_address, 0)}
    CLOUD
}

output "on_premises_instance_access" {
  value = <<ONPREM

  ### You can access the simulated on-premises instance using the following SSH command:###
    ssh -F scripts/ssh.config root@${ibm_compute_vm_instance.onprem_vsi.ipv4_address}
    ONPREM
}