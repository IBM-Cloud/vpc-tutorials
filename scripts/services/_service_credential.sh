#!/bin/bash

function createServiceCredential {
    local key_protect_create_response
    local key_protect_list_response
    local key_crn
    local key_id

    log_info "${FUNCNAME[0]}: ibmcloud resource service-key-create. started."

    resource_service_keys=$(ibmcloud resource service-keys --output json)
    [ $? -ne 0 ] && log_error "${FUNCNAME[0]}: Error reading resource service keys." && log_error "${resource_service_keys}" && return 1

    if [ ! -z "${resource_service_keys}" ]; then
        resource_service_key=$(echo ${resource_service_keys} | jq -c --arg service_key_name ${service_key_name} --arg service_crn ${service_crn} '.[] | select(.name == $service_key_name) | select(.source_crn == $service_crn)')
    fi
    
    if [ -z "${resource_service_key}" ]; then
        ibmcloud resource service-key-create ${service_key_name} ${service_key_role} --instance-name ${service_instance_name}
        [ $? -ne 0 ] && log_error "${FUNCNAME[0]}: Error creating service creential ${service_key_name}." && return 1

        resource_service_keys=$(ibmcloud resource service-keys --output json)
        [ $? -ne 0 ] && log_error "${FUNCNAME[0]}: Error reading resource service keys." && log_error "${resource_service_keys}" && return 1

        if [ ! -z "${resource_service_keys}" ]; then
            resource_service_key=$(echo ${resource_service_keys} | jq -c --arg service_key_name ${service_key_name} --arg service_crn ${service_crn} '.[] | select(.name == $service_key_name) | select(.source_crn == $service_crn)')
        fi
    else
        log_warning "${FUNCNAME[0]}: Existing key found, re-using."
    fi

    service_key_guid=$(echo "$resource_service_key" | jq -r '.guid')
    service_key_id=$(echo "$resource_service_key" | jq -r '.id')

    jq -r --arg service_key_guid "${service_key_guid}" '(.service_instances[]? | .service_credentials[0] | .guid) = $service_key_guid' ${configFile} > "tmp.json" && mv "tmp.json" ${configFile}
    jq -r --arg service_key_id "${service_key_id}" '(.service_instances[]? | .service_credentials[0] | .id) = $service_key_id' ${configFile} > "tmp.json" && mv "tmp.json" ${configFile}
    
    log_info "${FUNCNAME[0]}: ibmcloud resource service-key-create. done."

    return 0
}