# floating IP address attached to the bastion
output "floating_ip_address" {
  value = ibm_is_floating_ip.bastion.address
}

# bastion maintenance security group. Add this to the instances that require access from the bastian
output "security_group_id" {
  value = ibm_is_security_group.maintenance.id
}

