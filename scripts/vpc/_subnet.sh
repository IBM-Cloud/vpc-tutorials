#!/bin/bash

function createSubnet {
    local vpc_id
    local subnet_id
    local subnet_cidr
    local subnet_response
    local pgw_id
    local p_public_gateway_id
    local is_subnet
    local is_running
    local status
    local subnets

    vpc_id=$(jq -r '(.vpc[].id)' ${configFile})
    if [ -z ${vpc_id} ]; then
        log_error "${FUNCNAME[0]}: A VPC ID was not found in the configuration file."
        return 1
    fi

    # check if a subnet already exist with that name.
    log_info "${FUNCNAME[0]}: Running ibmcloud is subnets --json"
    subnets=$(ibmcloud is subnets --json)
    [ $? -ne 0 ] && log_error "${FUNCNAME[0]}: error reading list of subnets." && log_error "${subnets}" && return 1

    subnet_response=$(echo "${subnets}" | jq -r --arg vpc_id ${vpc_id} --arg subnet_zone ${subnet_zone} --arg subnet_name ${subnet_name} '(.[] | select (.vpc.id == $vpc_id) | select(.zone.name == $subnet_zone) | select(.name == $subnet_name))')

    subnet_id=$(echo "$subnet_response" | jq -r '.id')
    subnet_cidr=$(echo "$subnet_response" | jq -r '.ipv4_cidr_block')

    if [ "${subnetAttachPublicGateway}" = "true"  ]; then
        pgw_id=$(jq -r --arg subnet_zone ${subnet_zone} '(.vpc[].public_gateways[]? | select(.zone == $subnet_zone) | .id)' ${configFile})
        if [ -z ${pgw_id} ]; then
            log_warning "${FUNCNAME[0]}: A Public Gateway was not found in the configuration file for zone ${subnet_zone}, it will not be configured."
            return 1
        fi
        
        p_public_gateway_id="--public-gateway-id ${pgw_id}"
    fi

    if [ ! -z ${subnet_id} ]; then
        log_warning "${FUNCNAME[0]}: Existing subnet ${subnet_name} with id ${subnet_id} cidr ${subnet_cidr} was found in zone ${subnet_zone}, re-using."

        if [ "${subnetAttachPublicGateway}" = "true"  ]; then
            log_info "${FUNCNAME[0]}: ibmcloud is subnet-update ${subnet_id} ${p_public_gateway_id} --json"
            subnet_response=$(ibmcloud is subnet-update ${subnet_id} ${p_public_gateway_id} --json)
            [ $? -ne 0 ] && log_error "${FUNCNAME[0]}: Error updating subnet and attaching public gateway." && log_error "${subnet_response}" && return 1
        fi
    else
        if [ "${debug}" = "false" ]; then

            log_info "${FUNCNAME[0]}: ibmcloud is subnet-create ${subnet_name} ${vpc_id} ${subnet_zone} --ipv4-address-count ${subnetIpv4AddressCount} ${p_public_gateway_id} --json"
            subnet_response=$(ibmcloud is subnet-create ${subnet_name} ${vpc_id} ${subnet_zone} --ipv4-address-count ${subnetIpv4AddressCount} ${p_public_gateway_id} --json)
            [ $? -ne 0 ] && log_error "${FUNCNAME[0]}: error creating subnet and attaching public gateway." && log_error "${subnet_response}" && return 1
            
            subnet_id=$(echo "$subnet_response" | jq -r '.id')
            subnet_cidr=$(echo "$subnet_response" | jq -r '.ipv4_cidr_block')
            if [ ! -z ${subnet_id} ]; then
                log_success "${FUNCNAME[0]}: Created subnet ${subnet_name} with id ${subnet_id} and cidr ${subnet_cidr}."
            else
                log_error "${FUNCNAME[0]}: Error creating subnet ${subnet_name}."
                return 1
            fi

            log_info "${FUNCNAME[0]}: Running ibmcloud is subnet --json"
            is_subnet=$(ibmcloud is subnet ${subnet_id} --json)
            [ $? -ne 0 ] && log_error "Error getting subnet details for ${subnet_id}." && log_error "${is_subnet}" && exit 1

            is_running=$(echo ${is_subnet} | jq -r '(.status != "available")')
            status=$(echo ${is_subnet} | jq -r '.status')

            until [ "$is_running" = false ]; do
                log_warning "${FUNCNAME[0]}: sleeping for 10 seconds while subnet ${subnet_id} is ${status}."
                sleep 10

                log_info "${FUNCNAME[0]}: Running ibmcloud is subnet --json"
                is_subnet=$(ibmcloud is subnet ${subnet_id} --json)
                [ $? -ne 0 ] && log_error "Error getting subnet details for ${subnet_id}." && log_error "${is_subnet}" && exit 1

                is_running=$(echo ${is_subnet} | jq -r '(.status != "available")')
                status=$(echo ${is_subnet} | jq -r '.status')
            done
            
        else
            log_warning "${FUNCNAME[0]}: --dry-run set for script execution, DID NOT create subnet ${subnet_name}."
        fi
    fi

    [ "${debug}" = "false" ] && jq -r --arg subnet_zone ${subnet_zone} --arg subnet_name ${subnet_name_temp} --arg subnet_id ${subnet_id} '(.vpc[].subnets[][] | .[] | select(.zone == $subnet_zone) | select (.name == $subnet_name) | .id) = $subnet_id' ${configFile} > "tmp.json" && mv "tmp.json" ${configFile}
    [ "${debug}" = "false" ] && jq -r --arg subnet_zone ${subnet_zone} --arg subnet_name ${subnet_name_temp} --arg subnet_cidr ${subnet_cidr} '(.vpc[].subnets[][] | .[] | select(.zone == $subnet_zone) | select (.name == $subnet_name) | .cidr) = $subnet_cidr' ${configFile} > "tmp.json" && mv "tmp.json" ${configFile}

    return 0
}

function deleteSubnet {
    log_info "${FUNCNAME[0]}: Running subnet-delete ${subnet_id} --force"
    ibmcloud is subnet-delete ${subnet_id} --force
    [ $? -ne 0 ] && log_error "${FUNCNAME[0]}: Error removing subnet ${subnet_id}." && return 1

    jq -r --arg subnet_id ${subnet_id} '(.vpc[]?.subnets[][]? | .[] | select(.id == $subnet_id) | .deleted_id) = $subnet_id' ${configFile} > "tmp.json" && mv "tmp.json" ${configFile}

    return 0
}

function detachSubnetPublicGateway {
    log_info "${FUNCNAME[0]}: Running subnet-public-gateway-detach ${subnet_id} --force"
    ibmcloud is subnet-public-gateway-detach ${subnet_id} --force
    [ $? -ne 0 ] && log_error "${FUNCNAME[0]}: Error removing public gateway from subnet ${subnet_id}." && return 1

    jq -r --arg subnet_id ${subnet_id} '(.vpc[]?.subnets[][]? | .[] | select(.id == $subnet_id) | .detached_pgw_id) = $subnet_id' ${configFile} > "tmp.json" && mv "tmp.json" ${configFile}

    return 0
}