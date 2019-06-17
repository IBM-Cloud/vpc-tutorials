#!/bin/bash

function createVPN {
    local vpc_id
    local pgw
    local public_gateways
    local pgw_id
    local vpn_gateways
    local vpn_id
    local vpn

    log_info "${FUNCNAME[0]}: ibmcloud is vpn-gateway-create ${vpn_name} ${subnet_id} --json. started."

    vpc_id=$(jq -r '(.vpc[].id)' ${configFile})
    if [ -z ${vpc_id} ]; then
      log_error "${FUNCNAME[0]}: A VPC ID was not found in the configuration file."
      return 1
    fi

    # check if a vpn already exist in the zone for that vpc, if so re-use it.
    log_info "${FUNCNAME[0]}: Running ibmcloud is vpn-gateways --json"
    vpn_gateways=$(ibmcloud is vpn-gateways --json)
    [ $? -ne 0 ] && log_error "${FUNCNAME[0]}: Error reading list of vpns." && log_error "${vpn_gateways}" && return 1
    
    vpn_id=$(echo "${vpn_gateways}" | jq -r --arg vpn_name ${vpn_name} --arg subnet_id ${subnet_id} '.[] | select (.name == $vpn_name) | select (.subnet.id == $subnet_id) | .id')

    if [ -z ${vpn_id} ]; then
      # check to determine if a vpn by that name already exist, we also know it is not in the zone based on previous search.
      log_info "${FUNCNAME[0]}: Running ibmcloud is vpn-gateways --json"
      vpn_gateways=$(ibmcloud is vpn-gateways --json)
      [ $? -ne 0 ] && log_error "${FUNCNAME[0]}: error reading list of vpn." && log_error "${vpn_gateways}" && return 1

      vpn_id=$(echo "${vpn_gateways}" | jq -r --arg vpn_name ${vpn_name} '.[] | select (.name == $vpn_name) | .id')

      if [ -z ${vpn_id} ] && [ ! -z ${subnet_id} ]; then
        if [ "${debug}" = "false" ]; then 
          log_info "${FUNCNAME[0]}: Running ibmcloud is vpn-gateway-create ${vpn_name} ${subnet_id} --json"
          vpn=$(ibmcloud is vpn-gateway-create ${vpn_name} ${subnet_id} --json)
          [ $? -ne 0 ] && log_error "${FUNCNAME[0]}: error creating vpn gateway." && log_error "${vpn}" && return 1
  
          vpn_id=$(echo "$vpn" | jq -r '.id')
          if [ ! -z ${vpn_id} ]; then
            log_success "${FUNCNAME[0]}: Created VPN ${vpn_name} with id ${vpn_id}."
          else
            log_error "${FUNCNAME[0]}: Error creating VPN ${vpn_name}."
            return 1
          fi
        else
          log_warning "${FUNCNAME[0]}: --dry-run set. DID NOT create VPN ${vpn_name}."
        fi
      else
        log_error "${FUNCNAME[0]}: A VPN ${vpn_name} with id ${vpn_id} already exists within this vpc, but it is not in your target subnet. Please use another name."
        return 1
      fi
    else
      log_warning "${FUNCNAME[0]}: Existing VPN ${vpn_name} with id ${vpn_id} was found in your target subnet, re-using."
    fi

    [ "${debug}" = "false" ] && jq -r --arg vpn_name_temp ${vpn_name_temp} --arg vpn_id ${vpn_id} '(.vpc[].vpn_gateways[] | select(.name == $vpn_name_temp) | .id) = $vpn_id' ${configFile} > "tmp.json" && mv "tmp.json" ${configFile}

    log_info "${FUNCNAME[0]}: ibmcloud is vpn-gateway-create ${vpn_name} ${vpc_id} ${vpn_zone} --json. done."

    return 0
}

function createVPNConnection {
    local vpc_id
    local local_subnets
    local local_subnet
    local local_cidr
    local key
    local value
    local local_cidr
    local p_local_cidr
    local remote_cidr
    local p_remote_cidr
    local remote_subnet
    local remote_subnets
    local connections
    local connection
    local pre_shared_key
    local remote_host
    local remote_host_address
    
    log_info "${FUNCNAME[0]}: ibmcloud is vpn-gateway-connection-create ${vpn_connection} ${vpn_id} ${vpn_zone} --json. started."

    vpc_id=$(jq -r '(.vpc[].id)' ${configFile})
    if [ -z ${vpc_id} ]; then
      log_error "${FUNCNAME[0]}: A VPC ID was not found in the configuration file."
      return 1
    fi

    connections=$(jq -r --arg vpn_id ${vpn_id} '(.vpc[]?.vpn_gateways[]? | select(.id == $vpn_id) | .connections[]? | .name)' ${configFile})
    for connection in $connections; do
      local_subnets=$(jq -c --arg vpn_id ${vpn_id} --arg connection ${connection} '(.vpc[]?.vpn_gateways[]? | select(.id == $vpn_id) | .connections[]? | select(.name == $connection) | .local_subnets[])' ${configFile})
      for local_subnet in $local_subnets; do
        key=$(echo ${local_subnet} | jq -r '.key')
        value=$(echo ${local_subnet} | jq -r '.value')

        [ -z $key ] && log_error "${FUNCNAME[0]}: Error getting key for vpn local." && return 1
        [ -z $value ] && log_error "${FUNCNAME[0]}: Error getting value for vpn local." && return 1

        if [ ${key} = "lookup" ]; then
          local_cidr=$(jq -r --arg value ${value} '(.vpc[].subnets[][] | .[] | select(.name == $value) | .cidr | select(.!=null))' ${configFile})
        fi
        
        if [ ${key} = "cidr" ]; then
          local_cidr=${value}
        fi

        [ -z $local_cidr ] && return 1

        p_local_cidr="${p_local_cidr} --local-cidr ${local_cidr}"
      done

      remote_subnets=$(jq -c --arg vpn_id ${vpn_id} --arg connection ${connection} '(.vpc[]?.vpn_gateways[]? | select(.id == $vpn_id) | .connections[]? | select(.name == $connection) | .remote_subnets[])' ${configFile})
      for remote_subnet in $remote_subnets; do
        key=$(echo ${remote_subnet} | jq -r '.key')
        value=$(echo ${remote_subnet} | jq -r '.value')

        [ -z $key ] && log_error "${FUNCNAME[0]}: Error getting key for vpn remote." && return 1
        [ -z $value ] && log_error "${FUNCNAME[0]}: Error getting value for vpn remote." && return 1

        if [ ${key} = "lookup" ]; then
          remote_cidr=$(jq -r --arg value ${value} '(.vpc[].subnets[][] | .[] | select(.name == $value) | .cidr | select(.!=null))' ${configFile})
        fi
        
        if [ ${key} = "cidr" ]; then
          remote_cidr=${value}
        fi

        [ -z $remote_cidr ] && return 1

        p_remote_cidr="${p_remote_cidr} --peer-cidr ${remote_cidr}"
      done

      pre_shared_key=$(jq -c --arg vpn_id ${vpn_id} --arg connection ${connection} '(.vpc[]?.vpn_gateways[]? | select(.id == $vpn_id) | .connections[]? | select(.name == $connection) | .pre_shared_key | select(.!=null))' ${configFile})

      if [ ! -z ${pre_shared_key} ]; then

        remote_host=$(jq -c --arg vpn_id ${vpn_id} --arg connection ${connection} '(.vpc[]?.vpn_gateways[]? | select(.id == $vpn_id) | .connections[]? | select(.name == $connection) | .remote_host | select(.!=null))' ${configFile})
        if [ ! -z ${remote_host} ]; then
          remote_host_address=$(jq -r --arg remote_host ${remote_host} '.classic_infrastructure[]? | .virtual_servers[]? | select(.name == $remote_host) | .address | select(.!=null)')

          if [ ! -z ${remote_host_address} ]; then
            if [ "${debug}" = "false" ]; then 
              log_info "${FUNCNAME[0]}: Running ibmcloud is vpn-gateway-connection-create ${connection} ${vpn_id} ${remote_host_address} ${pre_shared_key} --admin-state-up true ${p_local_cidr} ${p_remote_cidr}"
              ibmcloud is vpn-gateway-connection-create ${connection} ${vpn_id} ${remote_host_address} ${pre_shared_key} --admin-state-up true ${p_local_cidr} ${p_remote_cidr}
              [ $? -ne 0 ] && log_error "${FUNCNAME[0]}: Error adding a connection to vpn with id: ${vpn_id}." && return 1
            fi
          fi
        fi
      fi

    done

  return 0
}

function deleteVPN {
    log_info "${FUNCNAME[0]}: Running vpn-gateway-delete ${vpn_id} --force"
    ibmcloud is vpn-gateway-delete ${vpn_id} --force
    [ $? -ne 0 ] && log_error "${FUNCNAME[0]}: Error removing vpn ${vpn_id}." && return 1

    jq -r --arg vpn_id ${vpn_id} '(.vpc[]?.vpn_gateways[]? | select(.id == $vpn_id) | .deleted_id) = $vpn_id' ${configFile} > "tmp.json" && mv "tmp.json" ${configFile}

    return 0
}