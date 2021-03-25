output "instance_access" {
  value = <<EOF
  
  ### SSH into the  instance using the following SSH command:
        ssh -F scripts/ssh.config root@${ibm_is_floating_ip.vpc_vsi_app_fip[0].address}
  
  ### List all files under the /data0 mount point:
        ls -latr /data0

  ### Run the following command to confirm each of the services configured ran successfully.
        systemctl status instance-storage

        systemctl status app
  
  ### Run the following command to read the logs on the two services.

        journalctl -xe --no-pager | grep instance-storage

        journalctl -xe --no-pager | grep app

  --------------------------------------------------------------------------------
    
EOF
}

output "Floating_IP" {
  value = ibm_is_floating_ip.vpc_vsi_app_fip[0].address
}