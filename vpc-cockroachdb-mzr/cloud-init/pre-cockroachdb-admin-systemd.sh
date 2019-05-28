#!/bin/bash

log_info "${BASH_SOURCE[0]}: Getting IP addresses for all cockroachdb nodes."
cp ${config_template_file_dir}/cloud-init/${vsi_cloud_init} ${config_file_dir}/${vsi_cloud_init_file}.state.sh 

vsi_ipv4_addresses=$(jq -r '.vpc[].virtual_server_instances[]? | select(.type == "cockroachdb") | .primary_network_interface.primary_ipv4_address' ${configFile} | tr -d '\r')
node_counter=0
for vsi_ipv4_address in $vsi_ipv4_addresses; do
  if [ ! -z ${vsi_ipv4_address} ]; then
    node_counter=$((node_counter+1))
    awk '{if(NR==3){$0="node'${node_counter}'_address='${vsi_ipv4_address}'\n"$0; print $0} ;if(NR!=3){print $0}}' ${config_file_dir}/${vsi_cloud_init_file}.state.sh > "tmp.sh" && mv "tmp.sh" ${config_file_dir}/${vsi_cloud_init_file}.state.sh
  else
    return 1
  fi
done

for load_balancer in $(jq -c '.vpc[]?.load_balancers[]? | select(.type == "private")' ${configFile} | tr -d '\r'); do
  if [ ! -z ${load_balancer} ]; then
    load_balancer_hostname=$(echo ${load_balancer} | jq -r '.hostname | select (.!=null)')
    awk '{if(NR==3){$0="lb_hostname='${load_balancer_hostname}'\n"$0; print $0} ;if(NR!=3){print $0}}' ${config_file_dir}/${vsi_cloud_init_file}.state.sh > "tmp.sh" && mv "tmp.sh" ${config_file_dir}/${vsi_cloud_init_file}.state.sh

    load_balancer_addresses=$(echo ${load_balancer} | jq -r '.private_ips[]?.address | select (.!=null)')
    lb_address_counter=0
    for load_balancer_address in $load_balancer_addresses; do
      if [ ! -z ${load_balancer_address} ]; then
        lb_address_counter=$((lb_address_counter+1))
        awk '{if(NR==3){$0="lb'${lb_address_counter}'_address='${load_balancer_address}'\n"$0; print $0} ;if(NR!=3){print $0}}' ${config_file_dir}/${vsi_cloud_init_file}.state.sh > "tmp.sh" && mv "tmp.sh" ${config_file_dir}/${vsi_cloud_init_file}.state.sh
      fi
    done
  else
    return 1
  fi
done

return 0

return 1