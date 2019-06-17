#!/bin/bash

function createLoadBalancer {
    local vpc_id
    local load_balancer_id
    local load_balancer_hostname
    local subnets
    local subnet
    local subnet_id
    local p_subnet
    local load_balancers
    local load_balancer_create
    local provisioning_status_active
    local provisioning_status_check_counter=0
    local provisioning_status_check_max=36
    local load_balancer_private_ips
    local load_balancer_public_ips

    log_info "${FUNCNAME[0]}: ibmcloud is load-balancer-create ${load_balancer_name}. started."

    vpc_id=$(jq -r '(.vpc[].id)' ${configFile})
    if [ -z ${vpc_id} ]; then
        log_error "${FUNCNAME[0]}: A VPC ID was not found in the configuration file."
        return 1
    fi

    log_info "${FUNCNAME[0]}: Running ibmcloud is load-balancers --json"
    load_balancers=$(ibmcloud is load-balancers --json)
    [ $? -ne 0 ] && log_error "${FUNCNAME[0]}: Error reading list of load balancers." && log_error "${load_balancers}" && return 1

    load_balancer_id=$(echo "${load_balancers}" | jq -r --arg load_balancer_name ${load_balancer_name} '.[] | select (.name == $load_balancer_name) | .id')
    load_balancer_hostname=$(echo "${load_balancers}" | jq -r --arg load_balancer_name ${load_balancer_name} '.[] | select (.name == $load_balancer_name) | .hostname')
    load_balancer_private_ips=$(echo "${load_balancers}" | jq -c --arg load_balancer_name ${load_balancer_name} '.[] | select (.name == $load_balancer_name) | .private_ips | select(.!=null)')
    load_balancer_public_ips=$(echo "${load_balancers}" | jq -c --arg load_balancer_name ${load_balancer_name} '.[] | select (.name == $load_balancer_name) | .public_ips | select(.!=null)')
    
    if [[ -z ${load_balancer_id} ]]; then
      if [ "${debug}" = "false" ]; then 
      
        subnets=$(jq -r --arg load_balancer_name_temp ${load_balancer_name_temp} '.vpc[].load_balancers[] | select(.name == $load_balancer_name_temp) | .subnets[]' ${configFile} | tr -d '\r')

        for subnet in $subnets; do 
            subnet_id=$(jq -r --arg subnet ${subnet} '.vpc[].subnets[][] | .[] | select(.name == $subnet) | .id' ${configFile})
            p_subnet="${p_subnet} --subnet ${subnet_id}"
        done

        log_info "${FUNCNAME[0]}: Running ibmcloud is load-balancer-create ${load_balancer_name} ${load_balancer_type} ${p_subnet} --resource-group-name ${resource_group} --json"    
        load_balancer_create=$(ibmcloud is load-balancer-create ${load_balancer_name} ${load_balancer_type} ${p_subnet} --resource-group-name ${resource_group} --json)
        [ $? -ne 0 ] && log_error "${FUNCNAME[0]}: error creating load balancer." && log_error "${load_balancer_create}" && return 1
        
        load_balancer_id=$(echo "$load_balancer_create" | jq -r '.id')
        load_balancer_hostname=$(echo "$load_balancer_create" | jq -r '.hostname')
        load_balancer_private_ips=$(echo "${load_balancers}" | jq -r --arg load_balancer_name ${load_balancer_name} '.[] | select (.name == $load_balancer_name) | .private_ips | select(.!=null)')
        load_balancer_public_ips=$(echo "${load_balancers}" | jq -r --arg load_balancer_name ${load_balancer_name} '.[] | select (.name == $load_balancer_name) | .public_ips | select(.!=null)')

        if [[ ! -z ${load_balancer_id} ]]; then
            log_success "${FUNCNAME[0]}: Created load balancer ${load_balancer_name} with id ${load_balancer_id}."
        else
            log_error "${FUNCNAME[0]}: Error creating load balancer ${load_balancer_name}."
            return 1
        fi
      fi
    else
        log_warning "${FUNCNAME[0]}: Existing load balancer ${load_balancer_name} with id ${load_balancer_id} was found, re-using."
    fi

    [ "${debug}" = "false" ] && [ ! -z ${load_balancer_id} ] && jq -r --arg load_balancer_name_temp ${load_balancer_name_temp} --arg load_balancer_id ${load_balancer_id} '(.vpc[].load_balancers[] | select(.name == $load_balancer_name_temp) | .id) = $load_balancer_id' ${configFile} > "tmp.json" && mv "tmp.json" ${configFile}
    [ "${debug}" = "false" ] && [ ! -z ${load_balancer_hostname} ] && jq -r --arg load_balancer_name_temp ${load_balancer_name_temp} --arg load_balancer_hostname ${load_balancer_hostname} '(.vpc[].load_balancers[] | select(.name == $load_balancer_name_temp) | .hostname) = $load_balancer_hostname' ${configFile} > "tmp.json" && mv "tmp.json" ${configFile}
    [ "${debug}" = "false" ] && [ ! -z ${load_balancer_private_ips} ] && jq -r --arg load_balancer_name_temp ${load_balancer_name_temp} --argjson load_balancer_private_ips ${load_balancer_private_ips} '(.vpc[].load_balancers[] | select(.name == $load_balancer_name_temp) | .private_ips) = $load_balancer_private_ips' ${configFile} > "tmp.json" && mv "tmp.json" ${configFile}
    [ "${debug}" = "false" ] && [ ! -z ${load_balancer_public_ips} ] && jq -r --arg load_balancer_name_temp ${load_balancer_name_temp} --argjson load_balancer_public_ips ${load_balancer_public_ips} '(.vpc[].load_balancers[] | select(.name == $load_balancer_name_temp) | .public_ips) = $load_balancer_public_ips' ${configFile} > "tmp.json" && mv "tmp.json" ${configFile}

    log_info "${FUNCNAME[0]}: ibmcloud load-balancer-create ${load_balancer_name}. done."

    return 0
}

function createLoadBalancerWait {
    local vpc_id
    local load_balancer_id
    local load_balancer_hostname
    local subnets
    local subnet
    local subnet_id
    local p_subnet
    local load_balancers
    local load_balancer_create
    local provisioning_status_active
    local provisioning_status_check_counter=0
    local provisioning_status_check_max=36
    local status

    vpc_id=$(jq -r '(.vpc[].id)' ${configFile})
    if [ -z ${vpc_id} ]; then
        log_error "${FUNCNAME[0]}: A VPC ID was not found in the configuration file."
        return 1
    fi

    log_info "${FUNCNAME[0]}: checking load balancer(s) status before proceeding. started."

    log_info "${FUNCNAME[0]}: Running ibmcloud is load-balancers --json"
    load_balancers=$(ibmcloud is load-balancers --json)
    [ $? -ne 0 ] && log_error "${FUNCNAME[0]}: Error reading list of load balancers." && log_error "${load_balancers}" && return 1

    load_balancer_id=$(echo "${load_balancers}" | jq -r --arg load_balancer_name ${load_balancer_name} '.[] | select (.name == $load_balancer_name) | .id')
    load_balancer_hostname=$(echo "${load_balancers}" | jq -r --arg load_balancer_name ${load_balancer_name} '.[] | select (.name == $load_balancer_name) | .hostname')
    provisioning_status_active=$(echo "${load_balancers}" | jq -r --arg load_balancer_id ${load_balancer_id} '(.[] | select(.id == $load_balancer_id) | .provisioning_status != "active")')
    status=$(echo "${load_balancers}" | jq -r --arg load_balancer_id ${load_balancer_id} '.[] | select(.id == $load_balancer_id) | .provisioning_status')

    until [ "$provisioning_status_active" = false ]; do
        log_warning "${BASH_SOURCE[0]}: sleeping for 30 seconds while load balancer ${load_balancer_name} is ${status}."
        sleep 30
        log_info "${FUNCNAME[0]}: Running ibmcloud is load-balancers --json"
        load_balancers=$(ibmcloud is load-balancers --json)
        [ $? -ne 0 ] && log_error "${FUNCNAME[0]}: Error reading list of load balancers." && log_error "${load_balancers}" && return 1

        provisioning_status_active=$(echo "${load_balancers}" | jq -r --arg load_balancer_id ${load_balancer_id} '(.[] | select(.id == $load_balancer_id) | .provisioning_status != "active")')
    done

    log_info "${FUNCNAME[0]}: checking load balancer(s) status before proceeding. done."

    return 0
}

function createLoadBalancerPool {
    local load_balancer_id
    local pool_id
    local pool
    local load_balancer_pools

    load_balancer_id=$(jq -r --arg load_balancer_name_temp ${load_balancer_name_temp} '.vpc[].load_balancers[] | select(.name == $load_balancer_name_temp) | .id' ${configFile})
    if [[ -z ${load_balancer_id} ]]; then
        log_error "${FUNCNAME[0]}: A load balancer ID was not found in the configuration file for ${load_balancer_name_temp}."
        return 1
    fi

    # check if a pool already exist with that name.
    log_info "${FUNCNAME[0]}: ibmcloud is load-balancer-pool-create ${pool_name} ${load_balancer_id} --json. started."
    
    log_info "${FUNCNAME[0]}: Running ibmcloud is load-balancer-pools ${load_balancer_id} --json"
    load_balancer_pools=$(ibmcloud is load-balancer-pools ${load_balancer_id} --json)
    [ $? -ne 0 ] && log_error "${FUNCNAME[0]}: error reading list of load balancer pools." && log_error "${load_balancer_pools}" && return 1

    pool_id=$(echo "${load_balancer_pools}" | jq -r --arg pool_name ${pool_name} '.[] | select (.name == $pool_name) | .id')

    if [ -z ${pool_id} ]; then
        if [ "${debug}" = "false" ]; then 
            if [ "${health_monitor_type}" = "tcp" ]; then
                log_info "${FUNCNAME[0]}: Running ibmcloud is load-balancer-pool-create ${pool_name} ${load_balancer_id} ${pool_algorithm} ${pool_protocol} ${health_monitor_delay} ${health_monitor_max_retries} ${health_monitor_timeout} ${health_monitor_type} --json"
                pool=$(ibmcloud is load-balancer-pool-create ${pool_name} ${load_balancer_id} ${pool_algorithm} ${pool_protocol} ${health_monitor_delay} ${health_monitor_max_retries} ${health_monitor_timeout} ${health_monitor_type} --json)
                [ $? -ne 0 ] && log_error "${FUNCNAME[0]}: Error creating pool ${pool_name}." && log_error "${pool}" && return 1
            else
                log_info "${FUNCNAME[0]}: Running ibmcloud is load-balancer-pool-create ${pool_name} ${load_balancer_id} ${pool_algorithm} ${pool_protocol} ${health_monitor_delay} ${health_monitor_max_retries} ${health_monitor_timeout} ${health_monitor_type} --json"
                pool=$(ibmcloud is load-balancer-pool-create ${pool_name} ${load_balancer_id} ${pool_algorithm} ${pool_protocol} ${health_monitor_delay} ${health_monitor_max_retries} ${health_monitor_timeout} ${health_monitor_type} --json)
                [ $? -ne 0 ] && log_error "${FUNCNAME[0]}: Error creating pool ${pool_name}." && log_error "${pool}" && return 1
            fi

            pool_id=$(echo "$pool" | jq -r '.id')
            if [[ ! -z ${pool_id} ]]; then
                log_success "${FUNCNAME[0]}: Created pool ${pool_name} with id ${pool_id}."
            else
                log_error "${FUNCNAME[0]}: Error creating pool ${pool_name}."
                return 1
            fi
        fi
    else
        log_warning "${FUNCNAME[0]}: Existing pool ${pool_name} with id ${pool_id} was found, re-using."
    fi

    [ "${debug}" = "false" ] && jq -r --arg pool_name ${pool_name} --arg pool_id ${pool_id} '(.vpc[].load_balancers[].pools[] | select(.name == $pool_name) | .id) = $pool_id' ${configFile} > "tmp.json" && mv "tmp.json" ${configFile}

    log_info "${FUNCNAME[0]}: ibmcloud is load-balancer-pool-create ${pool_name} ${load_balancer_id} --json. done."

    return 0
}

function createLoadBalancerPoolMember {
    local load_balancer_pool_members
    local load_balancer_id
    local pool_id
    local member_create
    local member_id
    local member
    local provisioning_status_active
    local provisioning_status_check_counter=0
    local provisioning_status_check_max=18

    load_balancer_id=$(jq -r --arg load_balancer_name_temp ${load_balancer_name_temp} '.vpc[].load_balancers[] | select(.name == $load_balancer_name_temp) | .id' ${configFile})
    if [[ -z ${load_balancer_id} ]]; then
        log_error "${FUNCNAME[0]}: A load balancer ID was not found in the configuration file for ${load_balancer_name_temp}."
        return 1
    fi

    pool_id=$(jq -r --arg pool_name ${pool_name} '.vpc[].load_balancers[].pools[] | select(.name == $pool_name) | .id' ${configFile})
    if [[ -z ${pool_id} ]]; then
        log_error "${FUNCNAME[0]}: A pool ID was not found in the configuration file for ${pool_name}."
        return 1
    fi

    log_info "${FUNCNAME[0]}: ibmcloud is load-balancer-pool-member-create ${load_balancer_id} ${pool_id} ${member_port} ${member_address} --json. started"

    howmany "$pool_id"
    [ $? -ne 0 ] && log_error "Your configuration file includes the same pool name multiple times and that is not allowed. Please modify your ${configFile}." && return 1

    # check if a pool member already exist with that name.
    log_info "${FUNCNAME[0]}: Running ibmcloud is load-balancer-pool-members ${load_balancer_id} ${pool_id} --json"
    load_balancer_pool_members=$(ibmcloud is load-balancer-pool-members ${load_balancer_id} ${pool_id} --json)
    [ $? -ne 0 ] && log_error "${FUNCNAME[0]}: Error reading list of load balancer pool members." && log_error "${load_balancer_pool_members}" && return 1

    member_id=$(echo "${load_balancer_pool_members}" | jq -r --arg member_address ${member_address} '.[] | select (.target.address == $member_address) | .id')
    if [[ -z ${member_id} ]]; then
        log_info "${FUNCNAME[0]}: Running ibmcloud is load-balancer-pool-member-create ${load_balancer_id} ${pool_id} ${member_port} ${member_address} --json"
        member_create=$(ibmcloud is load-balancer-pool-member-create ${load_balancer_id} ${pool_id} ${member_port} ${member_address} --json)
        [ $? -ne 0 ] && log_error "${FUNCNAME[0]}: Error creating pool member ${member_name}." && log_error "${member_create}" && return 1

        member_id=$(echo "$member_create" | jq -r '.id')
        if [[ ! -z ${member_id} ]]; then
            log_info "${FUNCNAME[0]}: Running ibmcloud is load-balancer-pool-members ${load_balancer_id} ${pool_id} --json"
            load_balancer_pool_members=$(ibmcloud is load-balancer-pool-members ${load_balancer_id} ${pool_id} --json)
            [ $? -ne 0 ] && log_error "${FUNCNAME[0]}: Error reading list of load balancer pool members." && log_error "${load_balancer_pool_members}" && return 1
            
            provisioning_status_active=$(echo "${load_balancer_pool_members}" | jq -r --arg member_id ${member_id} '(.[] | select(.id == $member_id) | .provisioning_status != "active")')

            until [ "$provisioning_status_active" = false ]; do
                log_warning "${FUNCNAME[0]}: sleeping for 10 seconds while pool member ${member_name} is pending create."
                sleep 10

                log_info "${FUNCNAME[0]}: Running ibmcloud is load-balancer-pool-members ${load_balancer_id} ${pool_id} --json"
                load_balancer_pool_members=$(ibmcloud is load-balancer-pool-members ${load_balancer_id} ${pool_id} --json)
                [ $? -ne 0 ] && log_error "${FUNCNAME[0]}: Error reading list of load balancer pool members." && log_error "${load_balancer_pool_members}" && return 1
                
                provisioning_status_active=$(echo "${load_balancer_pool_members}" | jq -r --arg member_id ${member_id} '(.[] | select(.id == $member_id) | .provisioning_status != "active")')
            done

            log_success "${FUNCNAME[0]}: Created pool member ${member_name} with id ${member_id}."
        else
            log_error "${FUNCNAME[0]}: Error creating pool member ${member_name}."
            return 1
        fi
    else
        log_warning "${FUNCNAME[0]}: Existing pool member ${member_name} with id ${member_id} was found, re-using."
    fi
    
    jq -r --arg member_name ${member_name} --arg member_id ${member_id} '(.vpc[].load_balancers[].pools[].members[] | select(.name == $member_name) | .id) = $member_id' ${configFile} > "tmp.json" && mv "tmp.json" ${configFile}

    log_info "${FUNCNAME[0]}: ibmcloud is load-balancer-pool-member-create ${load_balancer_id} ${pool_id} ${member_port} ${member_address} --json. done"

    return 0
}

function createLoadBalancerListener {
    local load_balancers_listeners
    local load_balancer_id
    local pool_id
    local listener_id
    local provisioning_status_active
    local provisioning_status_check_counter=0
    local provisioning_status_check_max=18

    load_balancer_id=$(jq -r --arg load_balancer_name_temp ${load_balancer_name_temp} '.vpc[].load_balancers[] | select(.name == $load_balancer_name_temp) | .id' ${configFile})
    if [[ -z ${load_balancer_id} ]]; then
        log_error "${FUNCNAME[0]}: A load balancer ID was not found in the configuration file for ${load_balancer_name_temp}."
        return 1
    fi

    pool_id=$(jq -r --arg pool_name ${pool_name} '.vpc[].load_balancers[].pools[] | select(.name == $pool_name) | .id' ${configFile})
    if [[ -z ${pool_id} ]]; then
        log_error "${FUNCNAME[0]}: A pool ID was not found in the configuration file for ${pool_name}."
        return 1
    fi

    log_info "${FUNCNAME[0]}: ibmcloud is load-balancer-listener-create ${load_balancer_id} ${listener_port} ${listener_protocol} --default-pool ${pool_id} --json. started."

   # check if a listener already exist with that port.
    log_info "${FUNCNAME[0]}: Running ibmcloud is load-balancer-listeners ${load_balancer_id} --json"
    load_balancers_listeners=$(ibmcloud is load-balancer-listeners ${load_balancer_id} --json)
    [ $? -ne 0 ] && log_error "${FUNCNAME[0]}: error reading list of listeners." && log_error "${load_balancers_listeners}" && return 1

    listener_id=$(echo "${load_balancers_listeners}" | jq -r --arg listener_port ${listener_port} '.[] | select(.port == ($listener_port | tonumber)) | .id')
    if [[ -z ${listener_id} ]]; then
        log_info "${FUNCNAME[0]}: Running ibmcloud is load-balancer-listener-create ${load_balancer_id} ${listener_port} ${listener_protocol} --default-pool ${pool_id} --json"
        listener=$(ibmcloud is load-balancer-listener-create ${load_balancer_id} ${listener_port} ${listener_protocol} --default-pool ${pool_id} --json)
        [ $? -ne 0 ] && log_error "${FUNCNAME[0]}: Error creating listener for port ${listener_port}." && log_error "${listener}" && return 1

        listener_id=$(echo "$listener" | jq -r '.id')
        if [[ ! -z ${listener_id} ]]; then
            if [ "${debug}" = "false" ]; then 
                log_info "${FUNCNAME[0]}: Running ibmcloud is load-balancer-listeners ${load_balancer_id} --json"
                load_balancers_listeners=$(ibmcloud is load-balancer-listeners ${load_balancer_id} --json)
                [ $? -ne 0 ] && log_error "${FUNCNAME[0]}: Error reading list of load balancer listeners." && log_error "${load_balancers_listeners}" && return 1

                provisioning_status_active=$(echo "${load_balancers_listeners}" | jq -r --arg listener_id ${listener_id} '(.[] | select(.id == $listener_id) | .provisioning_status != "active")')

                until [ "$provisioning_status_active" = false ]; do
                    log_warning "${FUNCNAME[0]}: sleeping for 10 seconds while listener ${listener_port} is pending create."
                    sleep 10

                    log_info "${FUNCNAME[0]}: Running ibmcloud is load-balancer-listeners ${load_balancer_id} --json"
                    load_balancers_listeners=$(ibmcloud is load-balancer-listeners ${load_balancer_id} --json)
                    [ $? -ne 0 ] && log_error "${FUNCNAME[0]}: Error reading list of load balancer listeners." && log_error "${load_balancers_listeners}" && return 1

                    provisioning_status_active=$(echo "${load_balancers_listeners}" | jq -r --arg listener_id ${listener_id} '(.[] | select(.id == $listener_id) | .provisioning_status != "active")')
                done

                log_success "${FUNCNAME[0]}: Created listener for ${listener_port} with id ${listener_id}."
            fi
        else
            log_error "${FUNCNAME[0]}: Error creating listener for ${listener_port}."
            return 1
        fi
    else
        log_warning "${FUNCNAME[0]}: Existing listener port ${listener_port} with id ${listener_id} was found, re-using."
    fi
    
    [ "${debug}" = "false" ] && jq -r --arg listener_port ${listener_port} --arg listener_id ${listener_id} '(.vpc[].load_balancers[].listeners[] | select(.port == $listener_port) | .id) = $listener_id' ${configFile} > "tmp.json" && mv "tmp.json" ${configFile}

    log_info "${FUNCNAME[0]}: ibmcloud is load-balancer-listener-create ${load_balancer_id} ${listener_port} ${listener_protocol} --default-pool ${pool_id} --json. done."

    return 0
}

function deleteLoadBalancer {

    log_info "${FUNCNAME[0]}: Running load-balancer-delete ${load_balancer_id} --force"
    ibmcloud is load-balancer-delete ${load_balancer_id} --force
    [ $? -ne 0 ] && log_error "${FUNCNAME[0]}: Error removing load balancer ${load_balancer_id}." && return 1

    jq -r --arg load_balancer_id ${load_balancer_id} '(.vpc[]?.load_balancers[]? | select(.id == $load_balancer_id) | .deleted_id) = $load_balancer_id' ${configFile} > "tmp.json" && mv "tmp.json" ${configFile}

    return 0
}

function deleteLoadBalancerWait {
    local is_load_balancers_response

    log_info "${FUNCNAME[0]}: Running ibmcloud is load-balancers --json"
    is_load_balancers_response=$(ibmcloud is load-balancers --json)
    [ $? -ne 0 ] && log_error "${FUNCNAME[0]}: Error reading list of load balancers." && log_error "${is_load_balancers_response}" && return 1

    status=$(echo "${is_load_balancers_response}" | jq -r --arg load_balancer_id ${load_balancer_id} '.[] | select(.id == $load_balancer_id) | .provisioning_status')
    until [ -z ${status} ]; do
        log_warning "${BASH_SOURCE[0]}: sleeping for 30 seconds while load balancer ${load_balancer_id} is ${status}."
        sleep 30

        log_info "${FUNCNAME[0]}: Running ibmcloud is load-balancers --json"
        is_load_balancers_response=$(ibmcloud is load-balancers --json)
        [ $? -ne 0 ] && log_error "${FUNCNAME[0]}: Error reading list of load balancers." && log_error "${is_load_balancers_response}" && return 1
        
        status=$(echo "${is_load_balancers_response}" | jq -r --arg load_balancer_id ${load_balancer_id} '.[] | select(.id == $load_balancer_id) | .provisioning_status')
    done

    return 0
}