#!/bin/bash

app_repo=vpc-tutorials
app_directory=sampleapps/nodejs-graphql
# /${app_repo}/${app_directory}

log_info "${BASH_SOURCE[0]}: Running SSH script $vsi_ssh_init on $vsi_name using IP address $vsi_ipv4_address."

floating_ip=$(jq -r '.vpc[].virtual_server_instances[]? | select(.type == "cockroachdb-admin") | .floating_ip.address' ${configFile})

log_info "Checking if ${vsi_name} is ready for SSH using ${floating_ip} as jump host."
ssh -F "${config_template_file_dir}/ssh-init/ssh.config" -J root@${floating_ip} root@${vsi_ipv4_address} -t 'true'
return_value=$?
[ $return_value -ne 0 ] && log_warning "${BASH_SOURCE[0]}: Error SSH on ${vsi_ipv4_address}." && is_ssh_ready=false
[ $return_value -eq 0 ] && is_ssh_ready=true

until [ "$is_ssh_ready" = true ]; do
  log_warning "${FUNCNAME[0]}: Sleeping for 30 seconds while waiting for ${vsi_name} to be ready for SSH."
  sleep 30
  
  log_info "Checking if ${vsi_name} is ready for SSH using ${floating_ip} as jump host."
  ssh -F "${config_template_file_dir}/ssh-init/ssh.config" -J root@${floating_ip} root@${vsi_ipv4_address} -t 'true'
  return_value=$?
  [ $return_value -ne 0 ] && log_warning "${BASH_SOURCE[0]}: Error SSH on ${vsi_ipv4_address}." && is_ssh_ready=false
  [ $return_value -eq 0 ] && is_ssh_ready=true
done

log_info "Checking for cloud-init status on node ${vsi_name} using ${floating_ip} as jump host."
cloud_init_status=$(ssh -F "${config_template_file_dir}/ssh-init/ssh.config" -J root@${floating_ip} root@${vsi_ipv4_address} -t 'cloud-init status')

if [ "$cloud_init_status" = "status: running" ]; then
  is_init_ready=false
else 
  is_init_ready=true
fi 

until [ "$is_init_ready" = true ]; do
  log_warning "${FUNCNAME[0]}: Sleeping for 30 seconds while waiting for all cloud-init activities to complete. ${cloud_init_status}"
  sleep 30
  
  log_info "Checking for cloud-init status on node ${vsi_name} using ${floating_ip} as jump host."
  cloud_init_status=$(ssh -F "${config_template_file_dir}/ssh-init/ssh.config" -J root@${floating_ip} root@${vsi_ipv4_address} -t 'cloud-init status')

  if [ "$cloud_init_status" = "status: running" ]; then
    is_init_ready=false
  else 
    is_init_ready=true
  fi 
done

certs_directory=certs
ca_directory=cas

if [ ! -f "${config_template_file_dir}/local/certs/client.maxroach.key" ]; then
  log_info "${BASH_SOURCE[0]}: Copying certs to local directory for ${vsi_ipv4_address} using ${floating_ip} as jump host."
  if [ ! -z ${floating_ip} ]; then
    scp -F "${config_template_file_dir}/ssh-init/ssh.config" -r root@${floating_ip}:/${certs_directory} ${config_template_file_dir}/local/
    [ $? -ne 0 ] && log_error "${BASH_SOURCE[0]}: Error copying ${certs_directory} directory from ${floating_ip}." && return 1

    scp -F "${config_template_file_dir}/ssh-init/ssh.config" -r root@${floating_ip}:/${ca_directory} ${config_template_file_dir}/local/
    [ $? -ne 0 ] && log_error "${BASH_SOURCE[0]}: Error copying ${ca_directory} directory from ${floating_ip}." && return 1
  fi
fi

if [ ! -z ${floating_ip} ]; then
    log_info "${BASH_SOURCE[0]}: Creating certs directory on node ${vsi_ipv4_address} using ${floating_ip} as jump host."
    ssh -F "${config_template_file_dir}/ssh-init/ssh.config" -J root@${floating_ip} root@${vsi_ipv4_address} -t 'mkdir -p /vpc-tutorials/sampleapps/nodejs-graphql/certs'
    [ $? -ne 0 ] && log_warning "${BASH_SOURCE[0]}: cockroachdb service started with a warning on node ${vsi_ipv4_address}."

    log_info "${BASH_SOURCE[0]}: Copying certs to node ${vsi_ipv4_address} using ${floating_ip} as jump host."
    scp -F "${config_template_file_dir}/ssh-init/ssh.config" -r -o "ProxyJump root@${floating_ip}" "${config_template_file_dir}/local/certs/client.maxroach.key" root@${vsi_ipv4_address}:/${app_repo}/${app_directory}/certs/client.maxroach.key
    [ $? -ne 0 ] && log_error "${BASH_SOURCE[0]}: Error copying node.key to node ${vsi_ipv4_address}." && return 1
    
    scp -F "${config_template_file_dir}/ssh-init/ssh.config" -r -o "ProxyJump root@${floating_ip}" "${config_template_file_dir}/local/certs/client.maxroach.crt" root@${vsi_ipv4_address}:/${app_repo}/${app_directory}/certs/client.maxroach.crt
    [ $? -ne 0 ] && log_error "${BASH_SOURCE[0]}: Error copying node.crt to node ${vsi_ipv4_address}." && return 1

    scp -F "${config_template_file_dir}/ssh-init/ssh.config" -r -o "ProxyJump root@${floating_ip}" "${config_template_file_dir}/local/certs/ca.crt" root@${vsi_ipv4_address}:/${app_repo}/${app_directory}/certs/ca.crt
    [ $? -ne 0 ] && log_error "${BASH_SOURCE[0]}: Error copying node.crt to node ${vsi_ipv4_address}." && return 1

    lb_hostname=$(jq -c '.vpc[]?.load_balancers[]? | select(.type == "private") | .hostname | select(.!=null)' ${configFile})

cat > "${config_template_file_dir}/local/${vsi_ipv4_address}.config.json" <<- EOF
{
  "cookie": "some_ridiculously_long_string_of_your_choice_or_keep_this_one",
  "cockroach": {
    "user": "maxroach",
    "host": $lb_hostname,
    "database": "bank",
    "port": 26257
  }
}
EOF

    log_info "${BASH_SOURCE[0]}: Copying app configuration to node ${vsi_ipv4_address} using ${floating_ip} as jump host."
    scp -F "${config_template_file_dir}/ssh-init/ssh.config" -r -o "ProxyJump root@${floating_ip}" "${config_template_file_dir}/local/${vsi_ipv4_address}.config.json" root@${vsi_ipv4_address}:/${app_repo}/${app_directory}/config/config.json
    [ $? -ne 0 ] && log_error "${BASH_SOURCE[0]}: Error copying app configuration to node ${vsi_ipv4_address}." && return 1

    log_success "Starting the NodeJS sample app on node ${vsi_name} using ${floating_ip} as jump host."
    ssh -F "${config_template_file_dir}/ssh-init/ssh.config" -J root@${floating_ip} root@${vsi_ipv4_address} -t 'cd /vpc-tutorials/sampleapps/nodejs-graphql/ && pm2 start build/index.js && pm2 startup systemd && pm2 save'
    return_value=$?
    [ $return_value -ne 0 ] && log_warning "${BASH_SOURCE[0]}: Error starting pm2 service on ${vsi_ipv4_address}." && is_ready=false
    [ $return_value -eq 0 ] && is_ready=true

else
    log_error "${BASH_SOURCE[0]}: Error obtaining floating IP for admin server."
    return 1
fi

unset join_list_temp
unset join_list

log_info "${BASH_SOURCE[0]}: Completed SSH script $vsi_ssh_init on $vsi_name using IP address $vsi_ipv4_address."
