#!/bin/bash

# @todo
# - 
# - 

function createPublicGateway {
    local vpc_id
    local pgw
    local public_gateways
    local pgw_id

    vpc_id=$(jq -r '(.vpc[].id)' ${configFile})
    if [ -z ${vpc_id} ]; then
        log_error "${FUNCNAME[0]}: A VPC ID was not found in the configuration file."
        return 1
    fi

    log_info "${FUNCNAME[0]}: ibmcloud is public-gateway-create ${gateway_name} ${vpc_id} ${gateway_zone} --json. started."

    # check if a gateway already exist in the zone for that vpc, if so re-use it.
    pgw=$(ibmcloud is public-gateways --json | jq -r --arg vpc_id ${vpc_id} --arg gateway_zone ${gateway_zone} '.[] | select (.vpc.id == $vpc_id) | select(.zone.name == $gateway_zone)')
    [ $? -ne 0 ] && log_error "${FUNCNAME[0]}: error reading list of public gateways." && log_error "${pgw}" && return 1
    
    pgw_id=$(echo "$pgw" | jq -r '.id')

    if [ -z ${pgw_id} ]; then
        # check to determine if a gateway by that name already exist, we also know it is not in the zone based on previous search.
        public_gateways=$(ibmcloud is public-gateways --json)
        [ $? -ne 0 ] && log_error "${FUNCNAME[0]}: error reading list of public gateways." && log_error "${public_gateways}" && return 1

        pgw_id=$(echo "${public_gateways}" | jq -r --arg gateway_name ${gateway_name} '.[] | select (.name == $gateway_name) | .id')

        if [ -z ${pgw_id} ]; then
            if [ "${debug}" = "false" ]; then 
                pgw=$(ibmcloud is public-gateway-create ${gateway_name} ${vpc_id} ${gateway_zone} --json)
                [ $? -ne 0 ] && log_error "${FUNCNAME[0]}: error creating public gateway." && log_error "${pgw}" && return 1

                pgw_id=$(echo "$pgw" | jq -r '.id')
                if [ ! -z ${pgw_id} ]; then

                    public_gateways=$(ibmcloud is public-gateways --json)
                    [ $? -ne 0 ] && log_error "${FUNCNAME[0]}: Error reading list of public gateways." && log_error "${public_gateways}" && return 1

                    provisioning_status_active=$(echo "${public_gateways}" | jq -r --arg pgw_id ${pgw_id} '(.[] | select(.id == $pgw_id) | .status != "available")')
                    status=$(echo "${public_gateways}" | jq -r --arg pgw_id ${pgw_id} '.[] | select(.id == $pgw_id) | .status')

                    until [ "$provisioning_status_active" = false ]; do
                        log_warning "${BASH_SOURCE[0]}: sleeping for 30 seconds while public gateway ${gateway_name} is ${status}."
                        sleep 30
                        public_gateways=$(ibmcloud is public-gateways --json)
                        [ $? -ne 0 ] && log_error "${FUNCNAME[0]}: Error reading list of public gateways." && log_error "${public_gateways}" && return 1

                        provisioning_status_active=$(echo "${public_gateways}" | jq -r --arg pgw_id ${pgw_id} '(.[] | select(.id == $pgw_id) | .status != "available")')
                        status=$(echo "${public_gateways}" | jq -r --arg pgw_id ${pgw_id} '.[] | select(.id == $pgw_id) | .status')
                    done

                    log_success "${FUNCNAME[0]}: Created public gateway ${gateway_name} with id ${pgw_id}."
                else
                    log_error "${FUNCNAME[0]}: Error creating public gateway ${gateway_name}."
                    return 1
                fi

            else
                log_warning "${FUNCNAME[0]}: --dry-run set. DID NOT create Public Gateway ${gateway_name}."
            fi
        else
            log_error "${FUNCNAME[0]}: A Public Gateway ${gateway_name} with id ${pgw_id} already exists within this vpc, but it is not in your target zone. Please use another name."
            return 1
        fi
    else
            log_warning "${FUNCNAME[0]}: Existing Public Gateway ${gateway_name} with id ${pgw_id} was found in your target VPC, re-using."
    fi

    [ "${debug}" = "false" ] && jq -r --arg gateway_zone ${gateway_zone} --arg gateway_name_temp ${gateway_name_temp} --arg pgw_id ${pgw_id} '(.vpc[].public_gateways[] | select(.zone == $gateway_zone) | select(.name == $gateway_name_temp) | .id) = $pgw_id' ${configFile} > "tmp.json" && mv "tmp.json" ${configFile}

    log_info "${FUNCNAME[0]}: ibmcloud is public-gateway-create ${gateway_name} ${vpc_id} ${gateway_zone} --json. done."

    return 0
}

function deletePublicGateway {

    log_info "${FUNCNAME[0]}: Running public-gateway-delete ${pgw_id} --force"
    ibmcloud is public-gateway-delete ${pgw_id} --force
    [ $? -ne 0 ] && log_error "${FUNCNAME[0]}: Error removing public gateway ${pgw_id}." && return 1

    jq -r --arg pgw_id ${pgw_id} '(.vpc[]?.public_gateways[]? | select(.id == $pgw_id) | .deleted_id) = $pgw_id' ${configFile} > "tmp.json" && mv "tmp.json" ${configFile}

    return 0
}