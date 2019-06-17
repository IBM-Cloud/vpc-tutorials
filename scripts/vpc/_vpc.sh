#!/bin/bash

# @todo
# - 
# - 

function createVPC {
    local vpcs
    local vpc
    local vpc_id
    local vpc_create
    local vpc_default_security_group_id
    local vpc_default_security_group_name
    
    log_info "${FUNCNAME[0]}: ibmcloud is vpc-create ${vpc_name} --resource-group-name ${resource_group}. started."

    log_info "${FUNCNAME[0]}: Running ibmcloud is vpcs --json"
    vpcs=$(ibmcloud is vpcs --json)
    [ $? -ne 0 ] && log_error "${FUNCNAME[0]}: error reading list of vpcs." && log_error "${vpcs}" && return 1

    vpc=$(echo "${vpcs}" | jq -r --arg vpc_name ${vpc_name} '.[] | select (.name==$vpc_name) | {id, default_security_group}')

    vpc_id=$(echo "$vpc" | jq -r '.id')
    vpc_default_security_group_id=$(echo "$vpc" | jq -r '.default_security_group.id')
    vpc_default_security_group_name=$(echo "$vpc" | jq -r '.default_security_group.name')

    # check if to reuse existing VPC
    if [ -z ${vpc_id} ]; then
        if [ "${debug}" = "false" ]; then
            log_info "${FUNCNAME[0]}: Running ibmcloud is vpc-create ${vpc_name} --resource-group-name ${resource_group} --json"
            vpc_create=$(ibmcloud is vpc-create ${vpc_name} --resource-group-name ${resource_group} --json)
            [ $? -ne 0 ] && log_error "${FUNCNAME[0]}: error creating vpc ${vpc_name}." && log_error "${vpc_create}" && return 1

            vpc_id=$(echo "$vpc_create" | jq -r '.id')
            vpc_default_security_group_id=$(echo "$vpc_create" | jq -r '.default_security_group.id')
            vpc_default_security_group_name=$(echo "$vpc_create" | jq -r '.default_security_group.name')

            if [ ! -z ${vpc_id} ]; then
                log_success "${FUNCNAME[0]}: Created VPC ${vpc_name} with id ${vpc_id}."
            else
                log_error "${FUNCNAME[0]}: Error creating VPC ${vpc_name}."
                return 1
            fi
        else
            log_warning "${FUNCNAME[0]}: --dry-run set. DID NOT create vpc ${vpc_name} in resource group ${resource_group}"
        fi
    else
        log_warning "${FUNCNAME[0]}: Reusing VPC ${vpc_name} with id ${vpc_id}."
    fi

    if [ "${debug}" = "false" ]; then
        jq -r --arg vpc_name_temp ${vpc_name_temp} --arg vpc_id ${vpc_id} '(.vpc[] | select(.name == $vpc_name_temp) | .id) = $vpc_id' ${configFile} > "tmp.json" && mv "tmp.json" ${configFile}
        jq -r --arg vpc_name_temp ${vpc_name_temp} --arg vpc_default_security_group_id ${vpc_default_security_group_id} '(.vpc[] | select(.name == $vpc_name_temp) | .default_security_group.id) = $vpc_default_security_group_id' ${configFile} > "tmp.json" && mv "tmp.json" ${configFile}
        jq -r --arg vpc_name_temp ${vpc_name_temp} --arg vpc_default_security_group_name ${vpc_default_security_group_name} '(.vpc[] | select(.name == $vpc_name_temp) | .default_security_group.name) = $vpc_default_security_group_name' ${configFile} > "tmp.json" && mv "tmp.json" ${configFile}
    fi

    log_info "${FUNCNAME[0]}: ibmcloud is vpc-create ${vpc_name} --resource-group-name ${resource_group}. done."
    return 0
}

function deleteVPC {
    log_info "${FUNCNAME[0]}: Running vpc-delete ${vpc_id} --force"
    ibmcloud is vpc-delete ${vpc_id} --force
    [ $? -ne 0 ] && log_error "${FUNCNAME[0]}: Error removing VPC ${vpc_id}." && return 1

    jq -r --arg vpc_id ${vpc_id} '(.vpc[]? | select(.id == $vpc_id) | .deleted_id) = $vpc_id' ${configFile} > "tmp.json" && mv "tmp.json" ${configFile}

    return 0
}