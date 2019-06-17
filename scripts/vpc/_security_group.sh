#!/bin/bash

function createSecurityGroup {
    local vpc_id
    local group_id
    local group_response

    vpc_id=$(jq -r '(.vpc[].id)' ${configFile})
    if [ -z ${vpc_id} ]; then
        log_error "${FUNCNAME[0]}: A VPC ID was not found in the configuration file."
        return 1
    fi

    log_info "${FUNCNAME[0]}: ibmcloud is security-group-create ${security_group_name} $vpc_id --json. started."

    # check if a security group already exist with that name.
    log_info "${FUNCNAME[0]}: Running ibmcloud is security-groups --json"
    group_response=$(ibmcloud is security-groups --json)
    [ $? -ne 0 ] && log_error "${FUNCNAME[0]}: Error reading list of security groups." && log_error "${group_response}" && return 1
    
    group_id=$(echo ${group_response} | jq -r --arg vpc_id ${vpc_id} --arg security_group_name ${security_group_name} '.[] | select (.vpc.id == $vpc_id) | select (.name == $security_group_name) | .id')
    if [ -z ${group_id} ]; then
        if [ "${debug}" = "false" ]; then 
            log_info "${FUNCNAME[0]}: Running ibmcloud is security-group-create ${security_group_name} $vpc_id --json"
            group_response=$(ibmcloud is security-group-create ${security_group_name} $vpc_id --json)
            [ $? -ne 0 ] && log_error "${FUNCNAME[0]}: Error creating security group." && log_error "${group_response}" && return 1
            
            group_id=$(echo "$group_response" | jq -r '.id')
            if [ ! -z ${group_id} ]; then
                log_success "${FUNCNAME[0]}: Created security group ${security_group_name} with id ${group_id}."
            else
                log_error "${FUNCNAME[0]}: Error creating security group ${security_group_name}."
                return 1
            fi
        else
            log_warning "${FUNCNAME[0]}: --dry-run set, DID NOT create security group ${security_group_name}."
        fi
    else
        log_warning "${FUNCNAME[0]}: Existing security group ${security_group_name} with id ${group_id} was found in vpc, re-using."
    fi

    jq -r --arg security_group_name_temp ${security_group_name_temp} --arg group_id ${group_id} '(.vpc[].security_groups[] | select(.name == $security_group_name_temp) | .id) = $group_id' ${configFile} > "tmp.json" && mv "tmp.json" ${configFile}

    log_info "${FUNCNAME[0]}: ibmcloud is security-group-create ${security_group_name} $vpc_id --json. done."

    return 0
}

function createSecurityGroupRule {
    local group_id
    local rule_response
    local rule_id
    local rule
    local remote
    local remote_name
    local protocol
    local direction
    local port_min
    local port_max
    local key
    local value
    local security_group_rules

    log_info "${FUNCNAME[0]}: ibmcloud is security-group-rule-add. started."

    group_id=$(jq -r --arg security_group_name_temp ${security_group_name_temp} '(.vpc[].security_groups[] | select(.name == $security_group_name_temp) | .id)' ${configFile})
    if [ -z ${group_id} ]; then
        log_error "${FUNCNAME[0]}: A Security Group ID was not found in the configuration file."
        return 1
    fi

    for rule in $(jq -c --arg group_id ${group_id} '(.vpc[].security_groups[] | select(.id == $group_id) | .rules[])' ${configFile}); do
        protocol=$(echo ${rule} | jq -r '.protocol')
        direction=$(echo ${rule} | jq -r '.direction')
        port_min=$(echo ${rule} | jq -r '.port_min')
        port_max=$(echo ${rule} | jq -r '.port_max')
        key=$(echo ${rule} | jq -r '.remote.key')
        value=$(echo ${rule} | jq -r '.remote.value')

        [ -z $protocol ] && log_error "${FUNCNAME[0]}: Error getting protocol for rule of security group ${group_id}." && return 1
        [ -z $direction ] && log_error "${FUNCNAME[0]}: Error getting direction for rule of security group ${group_id}." && return 1
        [ -z $value ] && log_error "${FUNCNAME[0]}: Error getting remote.value for rule of security group ${group_id}." && return 1

        # check if a rule already exist so we don't recreate it.
        if [ ${key} = "lookup" ]; then
            remote=$(jq -r --arg value ${value} '(.vpc[].subnets[][] | .[] | select(.name == $value) | .cidr)' ${configFile})
            log_info "${FUNCNAME[0]}: Running ibmcloud is security-group-rules ${group_id} --json"
            security_group_rules=$(ibmcloud is security-group-rules ${group_id} --json)
            [ $? -ne 0 ] && log_error "${FUNCNAME[0]}: Error reading id for security rule." && log_error "${security_group_rules}" && return 1

            rule_id=$(echo "${security_group_rules}" | jq -r --arg port_min ${port_min} --arg port_max ${port_max} --arg remote ${remote} --arg direction ${direction} --arg protocol ${protocol} '.[] | select(.port_min == ($port_min | tonumber)) | select(.port_max == ($port_max |tonumber)) | select(.remote.cidr_block == $remote) | select(.direction == $direction) | select(.protocol == $protocol) | .id | select (.!=null)')
        fi

        if [ ${key} = "address" ]; then
            remote=${value}
            log_info "${FUNCNAME[0]}: Running ibmcloud is security-group-rules ${group_id} --json"
            security_group_rules=$(ibmcloud is security-group-rules ${group_id} --json)
            [ $? -ne 0 ] && log_error "${FUNCNAME[0]}: Error reading id for security rule." && log_error "${security_group_rules}" && return 1
            
            rule_id=$(echo "${security_group_rules}" | jq -r --arg port_min ${port_min} --arg port_max ${port_max} --arg remote ${remote} --arg direction ${direction} --arg protocol ${protocol} '.[] | select(.port_min == ($port_min | tonumber)) | select(.port_max == ($port_max |tonumber)) | select(.remote.address == $remote) | select(.direction == $direction) | select(.protocol == $protocol) | .id | select (.!=null)')
        fi
        
        if [ ${key} = "cidr" ]; then
            remote=${value}
            log_info "${FUNCNAME[0]}: Running ibmcloud is security-group-rules ${group_id} --json"
            security_group_rules=$(ibmcloud is security-group-rules ${group_id} --json)
            [ $? -ne 0 ] && log_error "${FUNCNAME[0]}: Error reading id for security rule." && log_error "${security_group_rules}" && return 1

            rule_id=$(echo "${security_group_rules}" | jq -r --arg port_min ${port_min} --arg port_max ${port_max} --arg remote ${remote} --arg direction ${direction} --arg protocol ${protocol} '.[] | select(.port_min == ($port_min | tonumber)) | select(.port_max == ($port_max |tonumber)) | select(.remote.cidr_block == $remote) | select(.direction == $direction) | select(.protocol == $protocol) | .id | select (.!=null)')
        fi

        if [ ${key} = "group" ]; then
            remote=$(jq -r --arg value ${value} '(.vpc[].security_groups[] | select(.name == $value) | .id)' ${configFile})
            remote_name=${resources_prefix}-${value}
            for x_use_resources_prefix_key in "${x_use_resources_prefix_keys[@]}"; do
                if [ "${x_use_resources_prefix_key}" = "security_groups" ]; then
                    remote_name=${value}
                fi
            done

            log_info "${FUNCNAME[0]}: Running ibmcloud is security-group-rules ${group_id} --json"
            security_group_rules=$(ibmcloud is security-group-rules ${group_id} --json)
            [ $? -ne 0 ] && log_error "${FUNCNAME[0]}: Error reading id for security rule." && log_error "${security_group_rules}" && return 1

            rule_id=$(echo "${security_group_rules}" | jq -r --arg port_min ${port_min} --arg port_max ${port_max} --arg remote_name ${remote_name} --arg direction ${direction} --arg protocol ${protocol} '.[] | select(.port_min == ($port_min | tonumber)) | select(.port_max == ($port_max |tonumber)) | select(.remote.name == $remote_name) | select(.direction == $direction) | select(.protocol == $protocol) | .id | select (.!=null)')
        fi

        if [ ${key} = "default" ]; then
            remote=$(jq -r '(.vpc[].default_security_group | .id)' ${configFile})
            remote_name=$(jq -r '(.vpc[].default_security_group | .name)' ${configFile})
            
            log_info "${FUNCNAME[0]}: Running ibmcloud is security-group-rules ${group_id} --json"
            security_group_rules=$(ibmcloud is security-group-rules ${group_id} --json)
            [ $? -ne 0 ] && log_error "${FUNCNAME[0]}: Error reading id for security rule." && log_error "${security_group_rules}" && return 1

            rule_id=$(echo "${security_group_rules}" | jq -r --arg port_min ${port_min} --arg port_max ${port_max} --arg remote_name ${remote_name} --arg protocol ${protocol} '.[] | select(.port_min == ($port_min | tonumber)) | select(.port_max == ($port_max |tonumber)) | select(.remote.name == $remote_name) | select(.direction == "outbound") | select(.protocol == $protocol) | .id | select (.!=null)')
        fi

        [ -z $remote ] && return 1

        if [ -z ${rule_id} ]; then
            if [ "${debug}" = "false" ]; then 

                if [ ${protocol} = "tcp" ] || [ ${protocol} = "udp" ]; then
                    log_info "${FUNCNAME[0]}: Adding rule using: ibmcloud is security-group-rule-add ${group_id} ${direction} ${protocol} --remote ${remote} --port-min ${port_min} --port-max ${port_max} --json"
                    rule_response=$(ibmcloud is security-group-rule-add ${group_id} ${direction} ${protocol} --remote ${remote} --port-min ${port_min} --port-max ${port_max} --json)
                    [ $? -ne 0 ] && log_error "${FUNCNAME[0]}: Error adding a rule to security group with group id: ${group_id}." && log_error "${rule_response}" && return 1
                    
                    if [ ${key} = "default" ]; then
                        log_info "${FUNCNAME[0]}: Adding rule using: ibmcloud is security-group-rule-add ${remote} inbound ${protocol} --remote ${group_id} --port-min ${port_min} --port-max ${port_max} --json"
                        rule_response=$(ibmcloud is security-group-rule-add ${remote} inbound ${protocol} --remote ${group_id} --port-min ${port_min} --port-max ${port_max} --json)
                        [ $? -ne 0 ] && log_error "${FUNCNAME[0]}: Error adding a rule to security group with group id: ${remote}." && log_error "${rule_response}" && return 1
                    fi

                elif [ ${protocol} = "all" ]; then
                    log_info "${FUNCNAME[0]}: Adding rule ${group_id} ${direction} ${protocol}"
                    rule_response=$(ibmcloud is security-group-rule-add ${group_id} ${direction} ${protocol} --json)
                    [ $? -ne 0 ] && log_error "${FUNCNAME[0]}: Error adding a rule to security group with group id: ${group_id}." && log_error "${rule_response}" && return 1
                else 
                    log_warning "${FUNCNAME[0]}: We don't support this protocol type ${protocol} yet, rule not added."
                    return 0
                fi

                rule_id=$(echo ${rule_response} | jq -r '.id')
                if [ ! -z ${rule_id} ]; then
                    log_success "${FUNCNAME[0]}: Created security group rule with id ${rule_id}."
                else
                    log_error "${FUNCNAME[0]}: Error creating security group rule for ${direction} --remote ${remote} ${protocol} --port-min ${port_min} --port-max ${port_max}."
                    return 1
                fi
            fi
        else
            log_warning "${FUNCNAME[0]}: Existing security group rule found with id ${rule_id}."
        fi
        
        rule_id=""
    done

    log_info "${FUNCNAME[0]}: ibmcloud is security-group-rule-add. done."

    return 0
}


function deleteSecurityGroupRule {
    local group_id
    local rule_id
    
    group_id=$(jq -r --arg security_group_name_temp ${security_group_name_temp} '(.vpc[].security_groups[] | select(.name == $security_group_name_temp) | .id)' ${configFile})
    if [ -z ${group_id} ]; then
        log_error "${FUNCNAME[0]}: A Security Group ID was not found in the configuration file."
        return 1
    fi

    if [ "${debug}" = "false" ]; then 
        for rule_id in $(ibmcloud is security-group-rules ${group_id} --json | jq -r '(.[] | .id)' | tr -d '\r'); do
            if [ ! -z ${rule_id} ]; then
                log_info "${FUNCNAME[0]}: Running ibmcloud is security-group-rule-delete ${group_id} ${rule_id} --force"
                ibmcloud is security-group-rule-delete ${group_id} ${rule_id} --force
                [ $? -ne 0 ] && log_warning "${FUNCNAME[0]}: Unable to delete rule id ${rule_id} from group ${group_id}."
            fi
        done
    fi

    return 0
}