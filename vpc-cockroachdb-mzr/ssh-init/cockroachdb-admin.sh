#!/bin/bash

vsi_ipv4_address=$(jq -r '[.vpc[].virtual_server_instances[]? | select(.type == "cockroachdb") | .primary_network_interface.primary_ipv4_address][0]' ${configFile})
floating_ip=$(jq -r '.vpc[].virtual_server_instances[]? | select(.type == "cockroachdb-admin") | .floating_ip.address' ${configFile})

log_info "Checking if ${vsi_name} is ready for SSH."
ssh -F "${config_template_file_dir}/ssh-init/ssh.config" root@${floating_ip} -t 'true'
return_value=$?
[ $return_value -ne 0 ] && log_warning "${BASH_SOURCE[0]}: Error SSH on ${floating_ip}." && is_ssh_ready=false
[ $return_value -eq 0 ] && is_ssh_ready=true

until [ "$is_ssh_ready" = true ]; do
  log_warning "${FUNCNAME[0]}: Sleeping for 30 seconds while waiting for all cloud-init activities to complete."
  sleep 30
  
  log_info "Checking if ${vsi_name} is ready for SSH using ${floating_ip} as jump host."
  ssh -F "${config_template_file_dir}/ssh-init/ssh.config" root@${floating_ip} -t 'true'
  return_value=$?
  [ $return_value -ne 0 ] && log_warning "${BASH_SOURCE[0]}: Error SSH on ${floating_ip}." && is_ssh_ready=false
  [ $return_value -eq 0 ] && is_ssh_ready=true
done

log_info "${BASH_SOURCE[0]}: Running SSH script $vsi_ssh_init on $vsi_name using IP address $vsi_ipv4_address."

if [ -f "${config_template_file_dir}/local/${vsi_ipv4_address}.cockroachdb.service.done" ]; then
    if [ ! -f "${config_template_file_dir}/local/${vsi_ipv4_address}.cockroachdb.init.done" ]; then

    log_info "${BASH_SOURCE[0]}: Pending for 120 seconds before running cockroach init command."
    sleep 120 

    log_info "${BASH_SOURCE[0]}: Initiating init of cockroachdb cluster using node ${vsi_ipv4_address}."
    ssh -F "${config_template_file_dir}/ssh-init/ssh.config" -t root@${floating_ip} "cockroach init --certs-dir=/certs --host=${vsi_ipv4_address}"

cat > "${config_template_file_dir}/local/${vsi_ipv4_address}.cockroachdb.init.done" <<- EOF
init
EOF

    fi
fi

log_info "${BASH_SOURCE[0]}: Completed SSH script $vsi_ssh_init on $vsi_name using IP address $vsi_ipv4_address."
