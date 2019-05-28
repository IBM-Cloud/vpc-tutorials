#!/bin/bash

log_info "${BASH_SOURCE[0]}: Running post-delete script. started."

# Wait for VSI to be gone, otherwise can't remove subnets
for vsi_list in $(jq -c '.vpc[]?.virtual_server_instances[]?' ${configFile}); do
    primary_ipv4_address=$(echo ${vsi_list} | jq -r '.primary_network_interface.primary_ipv4_address | select (.!=null)')

    if [ -f "${config_template_file_dir}/local/${primary_ipv4_address}.cockroachdb.service.done" ]; then
        rm -rf "${config_template_file_dir}/local/${primary_ipv4_address}.cockroachdb.service.done"
    fi

    if [ -f "${config_template_file_dir}/local/${primary_ipv4_address}.cockroachdb.init.done" ]; then
        rm -rf "${config_template_file_dir}/local/${primary_ipv4_address}.cockroachdb.init.done"
    fi
    
done

log_info "${BASH_SOURCE[0]}: Running post-delete script. done."