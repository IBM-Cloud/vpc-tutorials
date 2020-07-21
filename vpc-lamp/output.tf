

output "instance_access" {
  value = <<LAMP
  
  ### SSH into the instance using the following SSH command:
        ssh root@${ibm_is_floating_ip.vpc_vsi_fip.0.address}
  
  --------------------------------------------------------------------------------
    
LAMP

}

