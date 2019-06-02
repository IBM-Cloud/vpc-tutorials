#!/bin/bash

# @todo
# - 
# - 

function createVSI {
    local vpc_id
    local subnet_id
    local security_groups
    local security_group
    local security_group_id
    local security_group_id_list_temp
    local security_group_id_list
    local p_security_group_ids
    local ssh_keys_name
    local ssh_key_name
    local SSHKeys
    local ssh_key_id
    local ssh_key_ids
    local ssh_key_ids_list
    local p_key_ids
    local imageID
    local p_image_id
    local data_volume
    local key_crn
    local p_volume_attach
    local vsi_zone
    local instances_response
    local vsi_response
    local vsi_id
    local vsi_created_at
    local vsi_pni_id
    local vsi_pni_ipaddress

    vpc_id=$(jq -r '(.vpc[].id)' ${configFile})
    if [[ -z ${vpc_id} ]]; then
        log_error "${FUNCNAME[0]}: A VPC ID was not found in the configuration file."
        return 1
    fi

    subnet_id=$(jq -r --arg vsi_primary_subnet ${vsi_primary_subnet} '(.vpc[].subnets[][] | .[] | select(.name == $vsi_primary_subnet) | .id)' ${configFile})
    if [[ -z ${subnet_id} ]]; then
        log_error "${FUNCNAME[0]}: A subnet id was not found in the configuration file for ${vsi_primary_subnet}."
        return 1
    fi

    # vsi zone is based on where the subnet resides
    vsi_zone=$(jq -r --arg vsi_primary_subnet ${vsi_primary_subnet} '(.vpc[].subnets[][] | .[] | select(.name == $vsi_primary_subnet) | .zone)' ${configFile})
    if [[ -z ${vsi_zone} ]]; then
        log_error "${FUNCNAME[0]}: A zone was not found in the configuration file for ${vsi_primary_subnet}."
        return 1
    fi

    security_groups=$(jq -r --arg vsi_name_temp ${vsi_name_temp} '.vpc[].virtual_server_instances[] | select(.name == $vsi_name_temp) | .security_groups[]? | select (.!=null)' ${configFile} | tr -d '\r')
    for security_group in $security_groups; do 
        security_group_id=$(jq -r --arg security_group ${security_group} '.vpc[].security_groups[] | select(.name == $security_group) | .id' ${configFile})
        security_group_id_list_temp="${security_group_id_list_temp},${security_group_id}"
    done
    security_group_id_list=$(echo "${security_group_id_list_temp}" | sed 's/,//')

    if [ ! -z "${security_group_id_list}" ]; then
        p_security_group_ids="--security-group-ids ${security_group_id_list}"
    fi

    ssh_keys_name=$(jq -r '.ssh_keys[]? | select(.type == "vpc") | .name' ${configFile} | tr -d '\r')
    if [ -z "${ssh_keys_name}" ]; then
        log_error "${FUNCNAME[0]}: You need to configure at least one(1) ssh key with a key type of vpc."
        return 1
    fi

    SSHKeys=$(ibmcloud is keys --json)
    for ssh_key_name in $ssh_keys_name; do 
      ssh_key_id=$(echo $SSHKeys | jq -r --arg ssh_key_name ${ssh_key_name} '.[] | select (.name==$ssh_key_name) | .id | select (.!=null)')
      if [ ! -z "${ssh_key_id}" ]; then
        jq -r --arg ssh_key_id ${ssh_key_id} --arg ssh_key_name ${ssh_key_name} '(.ssh_keys[] | select(.name == $ssh_key_name) | .id) = $ssh_key_id' ${configFile} > "tmp.json" && mv "tmp.json" ${configFile}
      fi 
      ssh_key_ids="${ssh_key_ids},${ssh_key_id}"
    done
    ssh_key_ids_list=$(echo "${ssh_key_ids}" | sed 's/,//')

    if [ -z "${ssh_key_ids_list}" ]; then
        log_error "${FUNCNAME[0]}: Unable to find an id for any of the ssh key files supplied."
        return 1
    else
        p_key_ids="--key-ids ${ssh_key_ids_list}"
    fi

    imageID=$(ibmcloud is images --json | jq -r --arg vsi_image_name ${vsi_image_name} '.[] | select (.name==$vsi_image_name) | .id')
    if [ -z "${imageID}" ]; then
        log_error "${FUNCNAME[0]}: A image ID was not found for ${vsi_image_name}."
        return 1
    else
        p_image_id="--image-id ${imageID}"
    fi
    
    # --volume-attach value
    data_volume=$(jq -c --arg vsi_name_temp ${vsi_name_temp} '.vpc[].virtual_server_instances[] | select(.name == $vsi_name_temp) | .data_volume | select (.!=null)' ${configFile})
    if [ ! -z "${data_volume}" ]; then
        key_crn=$(jq -r '.service_instances[]? | select(.service_name == "kms") | .keys[0].crn | select (.!=null)' ${configFile})
        if [ -z "${key_crn}" ]; then
            log_error "${FUNCNAME[0]}: A key protect crn value was not found, unable to create data_volume."
            return 1
        else
            jq -r --arg vsi_name_temp ${vsi_name_temp} --arg key_crn ${key_crn} '(.vpc[].virtual_server_instances[] | select(.name == $vsi_name_temp) | .data_volume.volume.encryption_key.crn) = $key_crn' ${configFile} > "tmp.json" && mv "tmp.json" ${configFile}
            
            dataVolumeFile=${config_template_file_dir}/local/${vsi_name_temp}.dataVolume.json

            data_volume=$(jq -c --arg vsi_name_temp ${vsi_name_temp} '.vpc[].virtual_server_instances[] | select(.name == $vsi_name_temp) | .data_volume' ${configFile})
            echo [${data_volume}] > ${dataVolumeFile}

            data_volume_name_temp=$(jq -r '.[] | .name | select (.!=null)' ${dataVolumeFile})
            data_volume_name=${resources_prefix}-${data_volume_name_temp}
            for x_use_resources_prefix_key in "${x_use_resources_prefix_keys[@]}"; do
                if [ "${x_use_resources_prefix_key}" = "data_volume" ]; then
                    data_volume_name=${data_volume_name_temp}
                fi
            done

            volume_name_temp=$(jq -r '.[] | .volume.name | select (.!=null)' ${dataVolumeFile})
            volume_name=${resources_prefix}-${volume_name_temp}
            for x_use_resources_prefix_key in "${x_use_resources_prefix_keys[@]}"; do
                if [ "${x_use_resources_prefix_key}" = "volume" ]; then
                    volume_name=${volume_name_temp}
                fi
            done

            jq -r --arg data_volume_name ${data_volume_name} '(.[] | .name) = $data_volume_name' ${dataVolumeFile} > "tmp.json" && mv "tmp.json" ${dataVolumeFile}
            jq -r --arg volume_name ${volume_name} '(.[] | .volume.name) = $volume_name' ${dataVolumeFile} > "tmp.json" && mv "tmp.json" ${dataVolumeFile}

            p_volume_attach="--volume-attach @${dataVolumeFile}"
        fi

    fi

    if [ "${debug}" = "false" ]; then 
        # check if a vsi already exist with that name.
        # instances_response=$(ibmcloud is instances --json | jq -r --arg vsi_name ${vsi_name} '(.[] | select(.name == $vsi_name))')
        log_info "${FUNCNAME[0]}: Running ibmcloud is instances --json"
        instances_response=$(ibmcloud is instances --json)
        [ $? -ne 0 ] && log_error "${FUNCNAME[0]}: Error in getting list of instances. View response received:" && log_error "${instances_response}" && rm -f ${dataVolumeFile} && return 1

        vsi_response=$(echo "${instances_response}" | jq -r --arg vsi_name ${vsi_name} '(.[] | select(.name == $vsi_name))')
 
        if [ ! -z "${vsi_response}" ]; then
            vsi_id=$(echo "$vsi_response" | jq -r '.id')
            [ $? -ne 0 ] && log_error "${FUNCNAME[0]}: Error reading response from ibmcloud is instances. View response received:" && log_error "${vsi_response}" && return 1

            if [ -z ${vsi_id} ]; then
                log_error "${FUNCNAME[0]}: Error getting id from ibmcloud is instances. View response received:" && log_error "${vsi_response}" && return 1
            else
                log_warning "${FUNCNAME[0]}: Existing vsi found ${vsi_name} with id ${vsi_id} was found, re-using."
                rm -f ${dataVolumeFile}
            fi
        else
            if [ -z ${vsi_cloud_init} ]; then
                # log_info "${FUNCNAME[0]}: ibmcloud is instance-create ${vsi_name} $vpc_id $vsi_zone ${vsi_profile_name} ${subnet_id} ${vsi_port_speed} ${p_image_id} ${p_key_ids} ${p_security_group_ids} ${p_volume_attach} --json"
                # vsi_response=$(ibmcloud is instance-create ${vsi_name} $vpc_id $vsi_zone ${vsi_profile_name} ${subnet_id} ${vsi_port_speed} ${p_image_id} ${p_key_ids} ${p_security_group_ids} ${p_volume_attach} --json)

                log_info "${FUNCNAME[0]}: Running ibmcloud is instance-create ${vsi_name} $vpc_id $vsi_zone ${vsi_profile_name} ${subnet_id} ${p_image_id} ${p_key_ids} ${p_security_group_ids} ${p_volume_attach} --json"
                vsi_response=$(ibmcloud is instance-create ${vsi_name} $vpc_id $vsi_zone ${vsi_profile_name} ${subnet_id} ${p_image_id} ${p_key_ids} ${p_security_group_ids} ${p_volume_attach} --json)
                [ $? -ne 0 ] && log_error "${FUNCNAME[0]}: Error creating vsi. View response received:" && log_error "${vsi_response}" && return 1
                
                rm -f ${dataVolumeFile}
                
                vsi_id=$(echo "$vsi_response" | jq -r '.id')
                [ $? -ne 0 ] && log_error "${FUNCNAME[0]}: Error reading response from ibmcloud is instance-create. View response received:" && log_error "${vsi_response}" && return 1

                if [ -z ${vsi_id} ]; then
                    log_error "${FUNCNAME[0]}: Error getting id from ibmcloud is instance-create. View response received:" && log_error "${vsi_response}" && return 1
                else
                    log_success "${FUNCNAME[0]}: Created vsi ${vsi_name} with id ${vsi_id} OS only."
                fi
            else
                if [ -f "${config_template_file_dir}/cloud-init/pre-${vsi_cloud_init}" ]; then
                  . ${config_template_file_dir}/cloud-init/pre-${vsi_cloud_init}
                  [ $? -ne 0 ] && log_error "${FUNCNAME[0]}: Error in ${config_template_file_dir}/cloud-init/pre-${vsi_cloud_init}." && log_error "${vsi_response}" && return 1                

                  p_user_data="--user-data @${config_file_dir}/${vsi_cloud_init_file}.state.sh"
                else
                  p_user_data="--user-data @${config_template_file_dir}/cloud-init/${vsi_cloud_init}"
                fi
                
                # log_info "${FUNCNAME[0]}: ibmcloud is instance-create ${vsi_name} $vpc_id $vsi_zone ${vsi_profile_name} ${subnet_id} ${vsi_port_speed} ${p_image_id} ${p_key_ids} ${p_security_group_ids} ${p_volume_attach} ${p_user_data} --json"
                # vsi_response=$(ibmcloud is instance-create ${vsi_name} $vpc_id $vsi_zone ${vsi_profile_name} ${subnet_id} ${vsi_port_speed} ${p_image_id} ${p_key_ids} ${p_security_group_ids} ${p_volume_attach} ${p_user_data} --json)
                
                log_info "${FUNCNAME[0]}: Running ibmcloud is instance-create ${vsi_name} $vpc_id $vsi_zone ${vsi_profile_name} ${subnet_id} ${p_image_id} ${p_key_ids} ${p_security_group_ids} ${p_volume_attach} ${p_user_data} --json"
                vsi_response=$(ibmcloud is instance-create ${vsi_name} $vpc_id $vsi_zone ${vsi_profile_name} ${subnet_id} ${p_image_id} ${p_key_ids} ${p_security_group_ids} ${p_volume_attach} ${p_user_data} --json)
                [ $? -ne 0 ] && log_error "${FUNCNAME[0]}: error creating vsi." && log_error "${vsi_response}" && return 1                
                
                rm -f ${dataVolumeFile}

                vsi_id=$(echo "$vsi_response" | jq -r '.id')
                [ $? -ne 0 ] && log_error "${FUNCNAME[0]}: Error reading response from ibmcloud is instance-create. View response received:" && log_error "${vsi_response}" && return 1

                if [ -z ${vsi_id} ]; then
                    log_error "${FUNCNAME[0]}: Error getting id from ibmcloud is instance-create. View response received:" && log_error "${vsi_response}" && return 1
                else
                    log_success "${FUNCNAME[0]}: Created vsi ${vsi_name} with id ${vsi_id} OS only."
                fi
            fi

        fi

        vsi_id=$(echo "$vsi_response" | jq -r '.id')
        vsi_created_at=$(echo "$vsi_response" | jq -r '.created_at')
        vsi_pni_id=$(echo "$vsi_response" | jq -r '.primary_network_interface.id')
        vsi_pni_ipaddress=$(echo "$vsi_response" | jq -r '.primary_network_interface.primary_ipv4_address')

        jq -r --arg vsi_name_temp ${vsi_name_temp} --arg vsi_id ${vsi_id} '(.vpc[].virtual_server_instances[] | select(.name == $vsi_name_temp) | .id) = $vsi_id' ${configFile} > "tmp.json" && mv "tmp.json" ${configFile}
        jq -r --arg vsi_name_temp ${vsi_name_temp} --arg vsi_created_at ${vsi_created_at} '(.vpc[].virtual_server_instances[] | select(.name == $vsi_name_temp) | .created_at) = $vsi_created_at' ${configFile} > "tmp.json" && mv "tmp.json" ${configFile}
        jq -r --arg vsi_name_temp ${vsi_name_temp} --arg vsi_pni_id ${vsi_pni_id} '(.vpc[].virtual_server_instances[] | select(.name == $vsi_name_temp) | .primary_network_interface.id) = $vsi_pni_id' ${configFile} > "tmp.json" && mv "tmp.json" ${configFile}
        jq -r --arg vsi_name_temp ${vsi_name_temp} --arg vsi_pni_ipaddress ${vsi_pni_ipaddress} '(.vpc[].virtual_server_instances[] | select(.name == $vsi_name_temp) | .primary_network_interface.primary_ipv4_address) = $vsi_pni_ipaddress' ${configFile} > "tmp.json" && mv "tmp.json" ${configFile}
    fi

    return 0
}

function reserveFloatingIP {
    local primary_network_interface_id
    local vsi_floatingip_response
    local vsi_floatingip_address
    local vsi_floatingip_created_at
    local vsi_floatingip_id
    local vpc_id

    vpc_id=$(jq -r '(.vpc[].id)' ${configFile})
    if [ -z ${vpc_id} ]; then
        log_error "${FUNCNAME[0]}: A VPC ID was not found in the configuration file."
        return 1
    fi

    primary_network_interface_id=$(jq -r --arg vsi_name_temp ${vsi_name_temp} '.vpc[].virtual_server_instances[] | select(.name == $vsi_name_temp) | .primary_network_interface.id | select (.!=null)' ${configFile})
    if [ -z ${primary_network_interface_id} ]; then
        log_error "${FUNCNAME[0]}: A network interface id was not found in the configuration file."
        return 1
    fi
    
    # check if a floating ip address already exist with for that primary_network_interface_id.
    log_info "${FUNCNAME[0]}: Running ibmcloud is floating-ips --json | jq -r --arg primary_network_interface_id ${primary_network_interface_id} '(.[] | select(.target.id == $primary_network_interface_id))'"
    vsi_floatingip_response=$(ibmcloud is floating-ips --json | jq -r --arg primary_network_interface_id ${primary_network_interface_id} '(.[] | select(.target.id == $primary_network_interface_id))')
    [ $? -ne 0 ] && log_error "${FUNCNAME[0]}: Error in getting list of floating ips" && log_error "${vsi_floatingip_response}" && return 1

    if [ -z "${vsi_floatingip_response}" ]; then
        # check if a floating ip address already exist with that name but no target set.
        log_info "${FUNCNAME[0]}: Running ibmcloud is floating-ips --json | jq -r --arg vsi_floatingip_name ${vsi_floatingip_name}  '(.[] | select(.name == $vsi_floatingip_name) | select(.target == null))'"
        vsi_floatingip_response=$(ibmcloud is floating-ips --json | jq -r --arg vsi_floatingip_name ${vsi_floatingip_name}  '(.[] | select(.name == $vsi_floatingip_name) | select(.target == null))')
        [ $? -ne 0 ] && log_error "${FUNCNAME[0]}: error in getting list of floating ips" && log_error "${vsi_floatingip_response}" && return 1

        if [ ! -z "${vsi_floatingip_response}" ]; then
            vsi_floatingip_id=$(echo "${vsi_floatingip_response}" | jq -r '.id')

            log_info "${FUNCNAME[0]}: Running ibmcloud is floating-ip-update ${vsi_floatingip_id} --nic-id ${primary_network_interface_id} --json"
            vsi_floatingip_response=$(ibmcloud is floating-ip-update ${vsi_floatingip_id} --nic-id ${primary_network_interface_id} --json)
            [ $? -ne 0 ] && log_error "${FUNCNAME[0]}: Error updating floating ip ${vsi_floatingip_name}." && log_error "${vsi_floatingip_response}" && return 1

            vsi_floatingip_address=$(echo "${vsi_floatingip_response}" | jq -r '.address')
            vsi_floatingip_created_at=$(echo "${vsi_floatingip_response}" | jq -r '.created_at')
            vsi_floatingip_id=$(echo "${vsi_floatingip_response}" | jq -r '.id')

            jq -r --arg vsi_name_temp ${vsi_name_temp} --arg vsi_floatingip_address ${vsi_floatingip_address} '(.vpc[].virtual_server_instances[] | select(.name == $vsi_name_temp) | .floating_ip.address) = $vsi_floatingip_address' ${configFile} > "tmp.json" && mv "tmp.json" ${configFile}
            jq -r --arg vsi_name_temp ${vsi_name_temp} --arg vsi_floatingip_created_at ${vsi_floatingip_created_at} '(.vpc[].virtual_server_instances[] | select(.name == $vsi_name_temp) | .floating_ip.created_at) = $vsi_floatingip_created_at' ${configFile} > "tmp.json" && mv "tmp.json" ${configFile}
            jq -r --arg vsi_name_temp ${vsi_name_temp} --arg vsi_floatingip_id ${vsi_floatingip_id} '(.vpc[].virtual_server_instances[] | select(.name == $vsi_name_temp) | .floating_ip.id) = $vsi_floatingip_id' ${configFile} > "tmp.json" && mv "tmp.json" ${configFile}
            return 0
        fi
    fi

    if [ -z "${vsi_floatingip_response}" ]; then
        # check if a floating ip address already exist with that name target set, i.e. because of checks above for a different interface.
        log_info "${FUNCNAME[0]}: Running ibmcloud is floating-ips --json | jq -r --arg vsi_floatingip_name ${vsi_floatingip_name}  '(.[] | select(.name == $vsi_floatingip_name) | select(.target != null))'"
        vsi_floatingip_response=$(ibmcloud is floating-ips --json | jq -r --arg vsi_floatingip_name ${vsi_floatingip_name}  '(.[] | select(.name == $vsi_floatingip_name) | select(.target != null))')
        [ $? -ne 0 ] && log_error "${FUNCNAME[0]}: error in getting list of floating ips" && log_error "${vsi_floatingip_response}" && return 1

        if [ ! -z "${vsi_floatingip_response}" ]; then
            log_error "${FUNCNAME[0]}: A floating ip named ${vsi_floatingip_name} is already assigned to another network interface." && return 1
        fi
    fi

    if [ ! -z "${vsi_floatingip_response}" ]; then
        log_warning "${FUNCNAME[0]}: Existing floating ip found ${vsi_floatingip_name}, re-using."
    else
        log_info "${FUNCNAME[0]}: Running ibmcloud is floating-ip-reserve ${vsi_floatingip_name} --nic-id ${primary_network_interface_id} --json"
        vsi_floatingip_response=$(ibmcloud is floating-ip-reserve ${vsi_floatingip_name} --nic-id ${primary_network_interface_id} --json)
        [ $? -ne 0 ] && log_error "${FUNCNAME[0]}: error creating floating ip ${vsi_floatingip_name}." && log_error "${vsi_floatingip_response}" && return 1
    fi

    vsi_floatingip_address=$(echo "${vsi_floatingip_response}" | jq -r '.address')
    vsi_floatingip_created_at=$(echo "${vsi_floatingip_response}" | jq -r '.created_at')
    vsi_floatingip_id=$(echo "${vsi_floatingip_response}" | jq -r '.id')

    jq -r --arg vsi_name_temp ${vsi_name_temp} --arg vsi_floatingip_address ${vsi_floatingip_address} '(.vpc[].virtual_server_instances[] | select(.name == $vsi_name_temp) | .floating_ip.address) = $vsi_floatingip_address' ${configFile} > "tmp.json" && mv "tmp.json" ${configFile}
    jq -r --arg vsi_name_temp ${vsi_name_temp} --arg vsi_floatingip_created_at ${vsi_floatingip_created_at} '(.vpc[].virtual_server_instances[] | select(.name == $vsi_name_temp) | .floating_ip.created_at) = $vsi_floatingip_created_at' ${configFile} > "tmp.json" && mv "tmp.json" ${configFile}
    jq -r --arg vsi_name_temp ${vsi_name_temp} --arg vsi_floatingip_id ${vsi_floatingip_id} '(.vpc[].virtual_server_instances[] | select(.name == $vsi_name_temp) | .floating_ip.id) = $vsi_floatingip_id' ${configFile} > "tmp.json" && mv "tmp.json" ${configFile}

    return 0
}

function deleteVSI {
    log_info "${FUNCNAME[0]}: Running ibmcloud is instance-delete ${instance_id} --force"
    ibmcloud is instance-delete ${instance_id} --force
    [ $? -ne 0 ] && log_error "${FUNCNAME[0]}: Error removing instance ${instance_id}." && return 1

    jq -r --arg instance_id ${instance_id} '(.vpc[]?.virtual_server_instances[]? | select(.id == $instance_id) | .deleted_id) = $instance_id' ${configFile} > "tmp.json" && mv "tmp.json" ${configFile}
    return 0
}

function deleteVSIWait {
    local instances_response
    local status

    instances_response=$(ibmcloud is instances --json)
    [ $? -ne 0 ] && log_error "Error reading list of instances." && log_error "${instances_response}" && return 1

    status=$(echo "${instances_response}" | jq -r --arg instance_id ${instance_id} '.[] | select(.id == $instance_id) | .status')
    until [ -z ${status} ]; do
        log_warning "${FUNCNAME[0]}: Sleeping for 30 seconds while vsi ${instance_id} is ${status}."
        sleep 30

        instances_response=$(ibmcloud is instances --json)
        [ $? -ne 0 ] && log_error "Error reading list of instances." && log_error "${instances_response}" && return 1

        status=$(echo "${instances_response}" | jq -r --arg instance_id ${instance_id} '.[] | select(.id == $instance_id) | .status')
    done

    return 0
}

function deleteFIP {
    log_info "${FUNCNAME[0]}: Running ibmcloud is instance-network-interface-floating-ip-remove ${instance_id} ${nic_id} ${fip_id} --force"
    ibmcloud is instance-network-interface-floating-ip-remove ${instance_id} ${nic_id} ${fip_id} --force
    [ $? -ne 0 ] && log_error "${FUNCNAME[0]}: Error removing floating ip from ${instance_id}." && return 1

    jq -r --arg fip_id ${fip_id} '(.vpc[]?.virtual_server_instances[]? | select(.floating_ip.id == $fip_id) | .floating_ip.deleted_id) = $fip_id' ${configFile} > "tmp.json" && mv "tmp.json" ${configFile}

    return 0
}

function releaseFIP {
    log_info "${FUNCNAME[0]}: Running ibmcloud is floating-ip-release ${fip_id} --force "
    ibmcloud is floating-ip-release ${fip_id} --force
    [ $? -ne 0 ] && log_error "${FUNCNAME[0]}: Error releasing floating ip ${fip_id}." && return 1

    jq -r --arg fip_id ${fip_id} '(.vpc[]?.virtual_server_instances[]? | select(.floating_ip.id == $fip_id) | .floating_ip.released_id) = $fip_id' ${configFile} > "tmp.json" && mv "tmp.json" ${configFile}

    return 0
}

function createVSIWait {
    local vpc_id
    local vsi_response
    local vsi_id
    local instances_response
    local is_instance
    local is_running
    local status
    
    vpc_id=$(jq -r '(.vpc[].id)' ${configFile})
    if [[ -z ${vpc_id} ]]; then
        log_error "${FUNCNAME[0]}: A VPC ID was not found in the configuration file."
        return 1
    fi

    instances_response=$(ibmcloud is instances --json)
    [ $? -ne 0 ] && log_error "${FUNCNAME[0]}: Error in getting list of instances. View response received:" && log_error "${instances_response}" && return 1

    vsi_response=$(echo "${instances_response}" | jq -r --arg vsi_name ${vsi_name} '(.[] | select(.name == $vsi_name))')

    vsi_id=$(echo "$vsi_response" | jq -r '.id')
    [ $? -ne 0 ] && log_error "${FUNCNAME[0]}: Error reading response from ibmcloud is instances. View response received:" && log_error "${vsi_response}" && return 1

    if [ ! -z ${vsi_id} ]; then
        is_instance=$(ibmcloud is instance ${vsi_id} --json)
        [ $? -ne 0 ] && log_error "Error getting instance details for ${vsi_id}. View response received:" && log_error "${is_instance}" && exit 1

        is_running=$(echo ${is_instance} | jq -r '(.status != "running")')
        status=$(echo ${is_instance} | jq -r '.status')

        until [ "$is_running" = false ]; do
            log_warning "${FUNCNAME[0]}: Sleeping for 30 seconds while vsi ${vsi_name} with id ${vsi_id} is ${status}."
            sleep 30
            is_instance=$(ibmcloud is instance ${vsi_id} --json)
            [ $? -ne 0 ] && log_error "Error getting instance details for ${vsi_id}. View response received:" && log_error "${is_instance}" && exit 1

            is_running=$(echo ${is_instance} | jq -r '(.status != "running")')
            status=$(echo ${is_instance} | jq -r '.status')
        done
    fi

    return 0
}