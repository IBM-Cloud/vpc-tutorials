#!/bin/bash

function createKeyProtectRootKey {
    local key_protect_create_response
    local key_protect_list_response
    local key_crn
    local key_id

    log_info "${FUNCNAME[0]}: ibmcloud kp create. started."

    key_protect_list_response=$(ibmcloud kp list -c --instance-id ${service_instance_id} --output json | jq -r 'select (.!=null)')
    [ $? -ne 0 ] && log_error "${FUNCNAME[0]}: Error reading kp list ${service_instance_id}." && return 1

    if [ -z "${key_protect_list_response}" ]; then
        log_info "${FUNCNAME[0]}: Running ibmcloud kp create ${key_name} --instance-id ${service_instance_id} --output json."
        key_protect_create_response=$(ibmcloud kp create ${key_name} --instance-id ${service_instance_id} --output json)
        [ $? -ne 0 ] && log_error "${FUNCNAME[0]}: Error creating key ${key_name} in key protect instance ${service_instance_id}." && log_error "${key_protect_create_response}" && return 1

        log_info "${FUNCNAME[0]}: Running ibmcloud kp list -c --instance-id ${service_instance_id} --output json | jq -r 'select (.!=null)."
        key_protect_list_response=$(ibmcloud kp list -c --instance-id ${service_instance_id} --output json | jq -r 'select (.!=null)')
        [ $? -ne 0 ] && log_error "${FUNCNAME[0]}: Error reading kp list ${service_instance_id}." && log_error "${key_protect_list_response}" && return 1

        if [ -z "${key_protect_list_response}" ]; then
            log_error "${FUNCNAME[0]}: A key protect crn was not found for ${service_instance_name} with id ${service_instance_id}, unable to create data_volume without a key_protect key."
            return 1
        fi
    else
        log_warning "${FUNCNAME[0]}: Existing key found, re-using."
    fi

    key_crn=$(echo "$key_protect_list_response" | jq -r '.[]?.crn')
    key_id=$(echo "$key_protect_list_response" | jq -r '.[]?.id')

    jq -r --arg key_crn "${key_crn}" '(.service_instances[]? | select(.service_name == "kms") | .keys[0] | .crn) = $key_crn' ${configFile} > "tmp.json" && mv "tmp.json" ${configFile}
    jq -r --arg key_id "${key_id}" '(.service_instances[]? | select(.service_name == "kms") | .keys[0] | .id) = $key_id' ${configFile} > "tmp.json" && mv "tmp.json" ${configFile}
    
    log_info "${FUNCNAME[0]}: ibmcloud kp create. done."

    return 0
}

function createAuthorization {
    local iam_authorization_response
    local authorization_policies

    log_info "${FUNCNAME[0]}: ibmcloud iam authorization-policy-create. started."

    # check if one already exist
    log_info "${FUNCNAME[0]}: Running ibmcloud iam authorization-policies --output json"
    authorization_policies=$(ibmcloud iam authorization-policies --output json)
    [ $? -ne 0 ] && log_error "${FUNCNAME[0]}: Error in getting iam authorization-policies for ${source_service_name}." && log_error "${authorization_policies}" && return 1

    iam_authorization_response=$(echo "${authorization_policies}" | jq -r --arg source_service_name ${source_service_name} --arg source_service_role ${source_service_role} --arg service_name ${service_name} --arg service_instance_id ${service_instance_id} '.[] | select(.subjects[].attributes[].value == $source_service_name) | select(.roles[].display_name == $source_service_role) | select(.resources[].attributes[].value == $service_name) | select(.resources[].attributes[].value == $service_instance_id)')

    if [ -z "${iam_authorization_response}" ]; then
        log_info "${FUNCNAME[0]}: Running ibmcloud iam authorization-policy-create ${source_service_name} ${service_name} ${source_service_role} --target-service-instance-id ${service_instance_id} --output json" 
        iam_authorization_response=$(ibmcloud iam authorization-policy-create ${source_service_name} ${service_name} ${source_service_role} --target-service-instance-id ${service_instance_id} --output json)
        [ $? -ne 0 ] && log_error "${FUNCNAME[0]}: Error creating authorization policy ${source_service_name} to service instance id ${service_instance_id}." && log_error "${iam_authorization_response}" && return 1
    else
        log_warning "${FUNCNAME[0]}: Existing authorization found, re-using."
    fi

    authorization_id=$(echo "$iam_authorization_response" | jq -r '.id')

    jq -r --arg authorization_id "${authorization_id}" '(.service_instances[]? | select(.service_name == "kms") | .authorizations[0] | .id) = $authorization_id' ${configFile} > "tmp.json" && mv "tmp.json" ${configFile}

    log_info "${FUNCNAME[0]}: ibmcloud iam authorization-policy-create. done."

    return 0
}

function deleteKeyProtectRootKey {
    log_info "${FUNCNAME[0]}: Running ibmcloud kp delete ${key_id} --instance-id ${service_instance_guid}."

    ibmcloud kp delete ${key_id} --instance-id ${service_instance_guid}
    [ $? -ne 0 ] && log_error "${FUNCNAME[0]}: Error deleting key ${key_name} with id ${key_id} in key protect instance ${service_instance_guid}." && return 1

    jq -r --arg key_id "${key_id}" '(.service_instances[]? | select(.service_name == "kms") | .keys[0] | .deleted_id) = $key_id' ${configFile} > "tmp.json" && mv "tmp.json" ${configFile}

    return 0
}