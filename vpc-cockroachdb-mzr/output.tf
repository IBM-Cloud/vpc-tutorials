output "database_instances_access" {
  value = <<DATABASE
  
  ### You can access the cockroachdb node ${element(ibm_is_instance.vsi_database.*.name, 0)} using the following SSH command:
        ssh -F scripts/ssh.config -J root@${ibm_is_floating_ip.vpc_vsi_admin_fip[0].address} root@${element(
  ibm_is_instance.vsi_database.*.primary_network_interface.0.primary_ipv4_address,
  0,
  )}

  ### You can access the cockroachdb node ${element(ibm_is_instance.vsi_database.*.name, 1)} using the following SSH command:
        ssh -F scripts/ssh.config -J root@${ibm_is_floating_ip.vpc_vsi_admin_fip[0].address} root@${element(
  ibm_is_instance.vsi_database.*.primary_network_interface.0.primary_ipv4_address,
  1,
  )}

  ### You can access the cockroachdb node ${element(ibm_is_instance.vsi_database.*.name, 2)} using the following SSH command:
        ssh -F scripts/ssh.config -J root@${ibm_is_floating_ip.vpc_vsi_admin_fip[0].address} root@${element(
  ibm_is_instance.vsi_database.*.primary_network_interface.0.primary_ipv4_address,
  2,
  )}

  ### You can access the CockroachDB Web Admin UI on node ${element(ibm_is_instance.vsi_database.*.name, 0)}, using the following SSH command:
        ssh -F scripts/ssh.config -L 8080:${element(
  ibm_is_instance.vsi_database.*.primary_network_interface.0.primary_ipv4_address,
  0,
)}:8080 root@${ibm_is_floating_ip.vpc_vsi_admin_fip[0].address}

      and by pointing your browser to:
        http://localhost:8080

  --------------------------------------------------------------------------------
    
DATABASE

}

output "app_instances_access" {
  value = <<APP
  
  ### You can access the app instance ${element(ibm_is_instance.vsi_app.*.name, 0)} using the following SSH command:
        ssh -F scripts/ssh.config -J root@${ibm_is_floating_ip.vpc_vsi_admin_fip[0].address} root@${element(
  ibm_is_instance.vsi_app.*.primary_network_interface.0.primary_ipv4_address,
  0,
  )}

  ### You can access the app instance ${element(ibm_is_instance.vsi_app.*.name, 1)} using the following SSH command:
        ssh -F scripts/ssh.config -J root@${ibm_is_floating_ip.vpc_vsi_admin_fip[0].address} root@${element(
  ibm_is_instance.vsi_app.*.primary_network_interface.0.primary_ipv4_address,
  1,
  )}

  ### You can access the app instance ${element(ibm_is_instance.vsi_app.*.name, 2)} using the following SSH command:
        ssh -F scripts/ssh.config -J root@${ibm_is_floating_ip.vpc_vsi_admin_fip[0].address} root@${element(
  ibm_is_instance.vsi_app.*.primary_network_interface.0.primary_ipv4_address,
  2,
)}

  ### You can access the AppUI by pointing your browser to:
        ${format("http://%s/api/bank", ibm_is_lb.lb_public.hostname)}

  --------------------------------------------------------------------------------
    
APP

}

output "admin_instance_access" {
  value = <<ADMIN
  
  ### SSH into the admin instance using the following SSH command:
        ssh -F scripts/ssh.config root@${ibm_is_floating_ip.vpc_vsi_admin_fip[0].address}
  
  ### Using the internal IP address of node 1, issue the following command:
        cockroach sql --certs-dir=/certs --host=${element(
  ibm_is_instance.vsi_database.*.primary_network_interface.0.primary_ipv4_address,
  0,
)}

  ### Run the following CockroachDB SQL statements:
      ```sql
        CREATE USER IF NOT EXISTS maxroach;
      ```

      ```sql
        CREATE DATABASE bank;
      ```

      ```sql
        GRANT ALL ON DATABASE bank TO maxroach;
      ```

      ```sql
        CREATE TABLE bank.accounts (id UUID PRIMARY KEY DEFAULT gen_random_uuid(), transactiontime TIMESTAMPTZ DEFAULT current_timestamp(),  balance DECIMAL);
      ```

      Exit the SQL shell:

      ```sql
        \q
      ```
  --------------------------------------------------------------------------------
    
ADMIN

}

