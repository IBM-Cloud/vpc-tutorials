#!/bin/bash

log_info "${BASH_SOURCE[0]}: Running SSH script $vsi_ssh_init on $vsi_name using IP address $vsi_ipv4_address."

floating_ip=$(jq -r '.vpc[].virtual_server_instances[]? | select(.type == "cockroachdb-admin") | .floating_ip.address' ${configFile})
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
    ssh -F "${config_template_file_dir}/ssh-init/ssh.config" -J root@${floating_ip} root@${vsi_ipv4_address} -t 'mkdir -p /vpc-tutorials/vpc-cockroachdb-mzr/apps/nodejs-graphql-cockroachdb/certs'
    [ $? -ne 0 ] && log_warning "${BASH_SOURCE[0]}: cockroachdb service started with a warning on node ${vsi_ipv4_address}."

    log_info "${BASH_SOURCE[0]}: Copying certs to node ${vsi_ipv4_address} using ${floating_ip} as jump host."
    scp -F "${config_template_file_dir}/ssh-init/ssh.config" -r -o "ProxyJump root@${floating_ip}" "${config_template_file_dir}/local/certs/client.maxroach.key" root@${vsi_ipv4_address}:/vpc-tutorials/vpc-cockroachdb-mzr/apps/nodejs-graphql-cockroachdb/certs/client.maxroach.key
    [ $? -ne 0 ] && log_error "${BASH_SOURCE[0]}: Error copying node.key to node ${vsi_ipv4_address}." && return 1
    
    scp -F "${config_template_file_dir}/ssh-init/ssh.config" -r -o "ProxyJump root@${floating_ip}" "${config_template_file_dir}/local/certs/client.maxroach.crt" root@${vsi_ipv4_address}:/vpc-tutorials/vpc-cockroachdb-mzr/apps/nodejs-graphql-cockroachdb/certs/client.maxroach.crt
    [ $? -ne 0 ] && log_error "${BASH_SOURCE[0]}: Error copying node.crt to node ${vsi_ipv4_address}." && return 1

    scp -F "${config_template_file_dir}/ssh-init/ssh.config" -r -o "ProxyJump root@${floating_ip}" "${config_template_file_dir}/local/certs/ca.crt" root@${vsi_ipv4_address}:/vpc-tutorials/vpc-cockroachdb-mzr/apps/nodejs-graphql-cockroachdb/certs/ca.crt
    [ $? -ne 0 ] && log_error "${BASH_SOURCE[0]}: Error copying node.crt to node ${vsi_ipv4_address}." && return 1

    lb_hostname=$(jq -c '.vpc[]?.load_balancers[]? | select(.type == "private") | .hostname | select(.!=null)' ${configFile})

cat > "${config_template_file_dir}/local/${vsi_ipv4_address}.cockroachdb.json" <<- EOF
{
  "address": $lb_hostname
}
EOF

    log_info "${BASH_SOURCE[0]}: Copying app configuration to node ${vsi_ipv4_address} using ${floating_ip} as jump host."
    scp -F "${config_template_file_dir}/ssh-init/ssh.config" -r -o "ProxyJump root@${floating_ip}" "${config_template_file_dir}/local/${vsi_ipv4_address}.cockroachdb.json" root@${vsi_ipv4_address}:/vpc-tutorials/vpc-cockroachdb-mzr/apps/nodejs-graphql-cockroachdb/config/cockroachdb.json
    [ $? -ne 0 ] && log_error "${BASH_SOURCE[0]}: Error copying app configuration to node ${vsi_ipv4_address}." && return 1

    log_success "Starting the NodeJS sample app on node ${vsi_name} using ${floating_ip} as jump host."
    ssh -F "${config_template_file_dir}/ssh-init/ssh.config" -J root@${floating_ip} root@${vsi_ipv4_address} -t 'cd /vpc-tutorials/vpc-cockroachdb-mzr/apps/nodejs-graphql-cockroachdb/ && pm2 start build/index.js && pm2 startup systemd && pm2 save'

else
    log_error "${BASH_SOURCE[0]}: Error obtaining floating IP for admin server."
    return 1
fi

unset join_list_temp
unset join_list

log_info "${BASH_SOURCE[0]}: Completed SSH script $vsi_ssh_init on $vsi_name using IP address $vsi_ipv4_address."
