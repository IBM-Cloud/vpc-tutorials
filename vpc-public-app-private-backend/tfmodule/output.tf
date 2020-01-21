output "bastion_floating_ip_address" {
  value = module.bastion.floating_ip_address
}

output "frontend_network_interface_address" {
  value = ibm_is_instance.frontend.primary_network_interface[0].primary_ipv4_address
}

output "frontend_floating_ip_address" {
  value = ibm_is_floating_ip.frontend.address
}

output "backend_network_interface_address" {
  value = ibm_is_instance.backend.primary_network_interface[0].primary_ipv4_address
}

output "backend_floating_ip_address" {
  value = ibm_is_floating_ip.frontend.address
}

