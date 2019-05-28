#!/bin/bash

log_info "${BASH_SOURCE[0]}: Running SSH script $vsi_ssh_init on $vsi_name using IP address $vsi_ipv4_address."

if [ ! -f "${config_template_file_dir}/local/${vsi_ipv4_address}.credentials.json.done" ]; then

    service_instances=$(jq -c '.service_instances[]?' ${configFile} | tr -d '\r')
    for service_instance in $service_instances; do
        service_instance_name_temp=$(echo ${service_instance} | jq -r '.name | select (.!=null)')
        
        if [ ! -z ${service_instance_name_temp} ]; then
            service_instance_name=${resources_prefix}-${service_instance_name_temp}
            for x_use_resources_prefix_key in "${x_use_resources_prefix_keys[@]}"; do
                if [ "${x_use_resources_prefix_key}" = "service_instances" ]; then
                    service_instance_name=${service_instance_name_temp}
                fi
            done

            service_key_name=$(echo ${service_instance} | jq -r '.service_credentials[0]? | .name | select (.!=null)')
            if [ ! -z ${service_key_name} ]; then
                resource_service_key=$(ibmcloud resource service-key ${service_key_name} --output json)
                [ $? -ne 0 ] && log_error "${BASH_SOURCE[0]}: Error reading service key ${service_key_name}." && return 1
            fi
        fi
    done

    floating_ip=$(jq -r '.vpc[].virtual_server_instances[]? | select(.type == "app-admin") | .floating_ip.address' ${configFile})

    echo ${resource_service_key} > "${config_template_file_dir}/local/${vsi_ipv4_address}.credentials.json"

    scp -F "${config_template_file_dir}/ssh-init/ssh.config" -r -o "ProxyJump root@${floating_ip}" "${config_template_file_dir}/local/${vsi_ipv4_address}.credentials.json" root@${vsi_ipv4_address}:/vpc-tutorials/vpc-site2site-vpn/vpc-app-cos/
    [ $? -ne 0 ] && log_error "${BASH_SOURCE[0]}: Error copying service configuration to node ${vsi_ipv4_address}." && return 1

    mv "${config_template_file_dir}/local/${vsi_ipv4_address}.credentials.json" "${config_template_file_dir}/local/${vsi_ipv4_address}.credentials.json.done"

fi

log_info "${BASH_SOURCE[0]}: Completed SSH script $vsi_ssh_init on $vsi_name using IP address $vsi_ipv4_address."
