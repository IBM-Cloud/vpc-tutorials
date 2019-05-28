#!/bin/bash

function createServiceInstance {
    local service_instance_response
    local service_instance_guid
    local service_instance_id
    local service_instance_sub_type
    local service_instance_resource_plan_id
    local service_instance_resource_group_id
    local service_instance_crn
    local service_instance_region_id
    
    log_info "${FUNCNAME[0]}: ibmcloud resource service-instance-create. started."

    if [ $service_name = "cloud-object-storage" ]; then
        service_instances_response=$(ibmcloud resource service-instances --location global --output json)
        [ $? -ne 0 ] && log_error "${FUNCNAME[0]}: Error reading service instances." && log_error "${service_instances_response}" && return 1
    else
        service_instances_response=$(ibmcloud resource service-instances --location ${region} --output json)
        [ $? -ne 0 ] && log_error "${FUNCNAME[0]}: Error reading service instances." && log_error "${service_instances_response}" && return 1
    fi

    # check if service instance exist
    if [ ! -z "${service_instances_response}" ] && [ ! "${service_instances_response}" = "null" ]; then
        service_instance_response=$(echo "${service_instances_response}" | jq -r --arg service_name ${service_name} --arg service_instance_name ${service_instance_name} '.[] | select(.name == $service_instance_name)')
    fi

    if [ -z "${service_instance_response}" ]; then
        if [ "${debug}" = "false" ]; then 
            if [ $service_name = "cloud-object-storage" ]; then
                ibmcloud resource service-instance-create ${service_instance_name} ${service_name} ${service_plan_name} global 2>&1 >/dev/null
                [ $? -ne 0 ] && log_error "${FUNCNAME[0]}: Error creating service instance ${service_instance_name}." && return 1

                service_instance_response=$(ibmcloud resource service-instance ${service_instance_name} --location global --output json)
                [ $? -ne 0 ] && log_error "${FUNCNAME[0]}: Error reading service instance ${service_instance_name}." && log_error "${service_instance_response}" && return 1
            else
                ibmcloud resource service-instance-create ${service_instance_name} ${service_name} ${service_plan_name} ${region} 2>&1 >/dev/null
                [ $? -ne 0 ] && log_error "${FUNCNAME[0]}: Error creating service instance ${service_instance_name}." && return 1

                service_instance_response=$(ibmcloud resource service-instance ${service_instance_name} --location ${region} --output json)
                [ $? -ne 0 ] && log_error "${FUNCNAME[0]}: Error reading service instance ${service_instance_name}." && log_error "${service_instance_response}" && return 1
            fi

            service_instance_guid=$(echo "$service_instance_response" | jq -r '.[]?.guid | select (.!=null)')
            service_instance_id=$(echo "$service_instance_response" | jq -r '.[]?.id | select (.!=null)')
            [ ! $service_name = "cloud-object-storage" ] && service_instance_sub_type=$(echo "$service_instance_response" | jq -r '.[]?.sub_type | select (.!=null)')
            service_instance_resource_plan_id=$(echo "$service_instance_response" | jq -r '.[]?.resource_plan_id | select (.!=null)')
            service_instance_resource_group_id=$(echo "$service_instance_response" | jq -r '.[]?.resource_group_id | select (.!=null)')
            service_instance_crn=$(echo "$service_instance_response" | jq -r '.[]?.crn | select (.!=null)')
            service_instance_region_id=$(echo "$service_instance_response" | jq -r '.[]?.region_id | select (.!=null)')

            log_success "${FUNCNAME[0]}: Created service instance ${service_instance_name} with id ${service_instance_guid}."
        else
            log_warning "${FUNCNAME[0]}: --dry-run set. DID NOT create service instance ${service_instance_name}."
        fi
    else
        service_instance_guid=$(echo "$service_instance_response" | jq -r '.guid')
        service_instance_id=$(echo "$service_instance_response" | jq -r '.id')
        [ ! $service_name = "cloud-object-storage" ] && service_instance_sub_type=$(echo "$service_instance_response" | jq -r '.sub_type')
        service_instance_resource_plan_id=$(echo "$service_instance_response" | jq -r '.resource_plan_id')
        service_instance_resource_group_id=$(echo "$service_instance_response" | jq -r '.resource_group_id')
        service_instance_crn=$(echo "$service_instance_response" | jq -r '.crn')
        service_instance_region_id=$(echo "$service_instance_response" | jq -r '.region_id')

        log_warning "${FUNCNAME[0]}: Existing resource ${service_instance_name} with id ${service_instance_guid} was found in your account, re-using."
    fi

    if [ "${debug}" = "false" ]; then 
        jq -r --arg service_instance_name_temp ${service_instance_name_temp} --arg service_instance_guid ${service_instance_guid} '(.service_instances[] | select(.name == $service_instance_name_temp) | .guid) = $service_instance_guid' ${configFile} > "tmp.json" && mv "tmp.json" ${configFile}
        jq -r --arg service_instance_name_temp ${service_instance_name_temp} --arg service_instance_id ${service_instance_id} '(.service_instances[] | select(.name == $service_instance_name_temp) | .id) = $service_instance_id' ${configFile} > "tmp.json" && mv "tmp.json" ${configFile}
        [ ! $service_name = "cloud-object-storage" ] && jq -r --arg service_instance_name_temp ${service_instance_name_temp} --arg service_instance_sub_type ${service_instance_sub_type} '(.service_instances[] | select(.name == $service_instance_name_temp) | .sub_type) = $service_instance_sub_type' ${configFile} > "tmp.json" && mv "tmp.json" ${configFile}
        jq -r --arg service_instance_name_temp ${service_instance_name_temp} --arg service_instance_resource_plan_id ${service_instance_resource_plan_id} '(.service_instances[] | select(.name == $service_instance_name_temp) | .resource_plan_id) = $service_instance_resource_plan_id' ${configFile} > "tmp.json" && mv "tmp.json" ${configFile}
        jq -r --arg service_instance_name_temp ${service_instance_name_temp} --arg service_instance_resource_group_id ${service_instance_resource_group_id} '(.service_instances[] | select(.name == $service_instance_name_temp) | .resource_group_id) = $service_instance_resource_group_id' ${configFile} > "tmp.json" && mv "tmp.json" ${configFile}
        jq -r --arg service_instance_name_temp ${service_instance_name_temp} --arg service_instance_crn ${service_instance_crn} '(.service_instances[] | select(.name == $service_instance_name_temp) | .crn) = $service_instance_crn' ${configFile} > "tmp.json" && mv "tmp.json" ${configFile}
        jq -r --arg service_instance_name_temp ${service_instance_name_temp} --arg service_instance_region_id ${service_instance_region_id} '(.service_instances[] | select(.name == $service_instance_name_temp) | .region_id) = $service_instance_region_id' ${configFile} > "tmp.json" && mv "tmp.json" ${configFile}
    fi

    log_info "${FUNCNAME[0]}: ibmcloud resource service-instance-create. done."

    return 0
}

function deleteServiceInstance {
    local service_instance_delete_response
    
    log_info "${FUNCNAME[0]}: Running ibmcloud resource service-instance-delete ${service_instance_id} --force --recursive."

    ibmcloud resource service-instance-delete ${service_instance_id} --force --recursive
    [ $? -ne 0 ] && log_error "${FUNCNAME[0]}: Error deleting service instance ${service_instance_id}." && return 1
    
    jq -r --arg service_instance_guid ${service_instance_guid} '(.service_instances[] | select(.guid == $service_instance_guid) | .deleted_guid) = $service_instance_guid' ${configFile} > "tmp.json" && mv "tmp.json" ${configFile}
    jq -r --arg service_instance_id ${service_instance_id} '(.service_instances[] | select(.id == $service_instance_id) | .deleted_id) = $service_instance_id' ${configFile} > "tmp.json" && mv "tmp.json" ${configFile}
    
    return 0
}