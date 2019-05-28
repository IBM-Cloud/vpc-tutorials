#!/bin/bash
#set -ex

# Script to delete resources created for IBM Cloud Solution Tutorials
#
# (C) 2019 IBM
#

# Exit on errors
set -o errexit
set -o pipefail
# set -o nounset

# @todo

debug=false
createLogFile=false
config=false
configTemplate=false
vpc=false
directory="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
filename="${directory}/$(basename "${BASH_SOURCE[0]}")"
name="$(basename ${filename} .sh)"

. ${directory}/scripts/common/_package-strings-en.sh
. ${directory}/scripts/common/_utils.sh
. ${directory}/scripts/common/_ibmcloud-cli.sh
. ${directory}/scripts/vpc/_vpc.sh
. ${directory}/scripts/vpc/_public-gateway.sh
. ${directory}/scripts/vpc/_subnet.sh
. ${directory}/scripts/vpc/_security_group.sh
. ${directory}/scripts/vpc/_vsi.sh
. ${directory}/scripts/vpc/_load_balancer.sh
. ${directory}/scripts/services/_common.sh
. ${directory}/scripts/services/_key_protect.sh
. ${directory}/scripts/sl/_vs.sh

for arg in $@; do
    parameter=$(echo ${arg} | awk -F= '{ print $1 }')
    if [ "${parameter}" = "--trace" ]; then
        set -o xtrace
        IBMCLOUD_TRACE=true
    elif [ "${parameter}" = "--createLogFile" ]; then
        createLogFile=true
	elif [ "${parameter}" = "--config" ]; then
        config=true
        configFile=$(echo ${arg} | awk -F= '{ print $2 }')
    elif [ "${parameter}" = "--template" ]; then
        configTemplate=true
        configTemplateFile=$(echo ${arg} | awk -F= '{ print $2 }')      
    fi
done

config_file_dir=$(dirname "$configFile")
config_template_file_dir=$(dirname "$configTemplateFile")

if [ "${createLogFile}" = "true" ]; then
    log_file=${name}.$(date +%Y%m%d_%H%M%S).log
    exec 3>&1 1>>${log_file} 2>&1
fi

log_info "${BASH_SOURCE[0]}: Validating inputs and preparing for build."

# Since we have not validated that jq is installed, we are not able to use it yet.
if [ ! -f package-info.json ]; then
    log_error "${package_info_missing_msg1}"
    exit 1
else 
    set +o errexit
    scriptname=$(grep '"name":' package-info.json | awk -F\" '/name/{print $4; exit}')
    [ $? -ne 0 ] && log_error "${package_info_missing_msg1}" && exit 1
    [ -z "${scriptname}" ] && log_error "${package_info_missing_scriptname_msg1}" && exit 1

    scriptversion=$(grep '"version":' package-info.json | awk -F\" '/version/{print $4; exit}')
    [ $? -ne 0 ] && log_error "${package_info_missing_version_msg1}" && exit 1
    [ -z "${scriptversion}" ] && log_error "${package_info_missing_version_msg1}" && exit 1

    set -o errexit
fi

if [ "${config}" = "false" ] && [ "${vpc}" = "false" ]; then
    log_error "${BASH_SOURCE[0]}: ${usage_msg1_delete}"
    exit 1
fi

if [ ! -f "${configFile}" ]; then
    log_error "${BASH_SOURCE[0]}: Could not find config file ${configFile}."
    exit 1
fi

if [ "${configTemplate}" = "false" ]; then
    log_error "${BASH_SOURCE[0]}: ${usage_msg1_delete}"
    exit 1
fi

if [ ! -f "${configTemplateFile}" ]; then
    log_error "${BASH_SOURCE[0]}: Could not find config file ${configTemplateFile}."
    exit 1
fi

# Verifying jq is installed/in the path.
type jq >/dev/null 2>&1 || { log_error "${jq_missing_msg1}" "${jq_missing_msg2}"; exit 1; }

# Verifying installed plugins versions.
plugins=$(jq -r '.plugins[].name' package-info.json | tr -d '\r')
plugin_error=0
for plugin in ${plugins}; do
    version=$(jq -r --arg plugin ${plugin} '.plugins[] | select(.name == $plugin) | .version' package-info.json)
    set +o errexit    
    verifyPlugin ${plugin} ${version}
    [ $? -ne 0 ] && plugin_error=1 && continue
    set -o errexit
done
[ $plugin_error -ne 0 ] && log_error "${BASH_SOURCE[0]}: Error encountered during plugin verification, pease review log." && exit 1

if jq -e . ${configFile} >/dev/null 2>&1; then
    log_info "${BASH_SOURCE[0]}: The provided configuration file ${configFile} was successfully parsed."
else
    log_error "${BASH_SOURCE[0]}: The provided configuration file ${configFile} failed parsing, please check it is a valid json."
fi

# Setting target for region and resource group
region=$(jq -r '.region | select (.!=null)' ${configFile})
resource_group=$(jq -r '.resource_group | select (.!=null)' ${configFile})
if [ ! -z ${region} ] && [ ! -z ${resource_group} ]; then
    set +o errexit
    setICTarget
    [ $? -ne 0 ] && exit 1
    set -o errexit
else
    log_error "${BASH_SOURCE[0]}: The provided configuration file ${configFile} is missing required values."
    exit 1
fi

log_info "${BASH_SOURCE[0]}: Completed validations, ready for delete."

# VPC Infrastructure - Delete floating IP
for instance_fip_nic_ids in $(jq -c '.vpc[]?.virtual_server_instances[]? | select(.floating_ip.id != null) | { instance_id: .id, fip_id: .floating_ip.id, deleted_id: .floating_ip.deleted_id, nic_id: .primary_network_interface.id }' ${configFile}); do
    instance_id=$(echo ${instance_fip_nic_ids} | jq -r '.instance_id | select (.!=null)')
    fip_id=$(echo ${instance_fip_nic_ids} | jq -r '.fip_id | select (.!=null)')
    nic_id=$(echo ${instance_fip_nic_ids} | jq -r '.nic_id | select (.!=null)')
    deleted_id=$(echo ${instance_fip_nic_ids} | jq -r '.deleted_id | select (.!=null)')

    if [ ! -z ${fip_id} ] && [ -z "${deleted_id}" ]; then
        set +o errexit
        deleteFIP
        [ $? -ne 0 ] && log_error "${BASH_SOURCE[0]}: deleteFIP returned with an error." && exit 1
        set -o errexit
    fi
done

# VPC Infrastructure - Delete Load Balancers
load_balancers=$(jq -c '.vpc[]?.load_balancers[]?' ${configFile} | tr -d '\r')
for load_balancer in $load_balancers; do
    load_balancer_id=$(echo ${load_balancer} | jq -r '.id | select (.!=null)')
    deleted_id=$(echo ${load_balancer} | jq -r '.deleted_id | select (.!=null)')

    if [ ! -z "${load_balancer_id}" ] && [ -z "${deleted_id}" ]; then
        set +o errexit
        deleteLoadBalancer
        [ $? -ne 0 ] && log_error "${BASH_SOURCE[0]}: deleteLoadBalancer returned with an error." && exit 1
        set -o errexit
    fi
done

# VPC Infrastructure - Detach Public Gateway from Subnet
for subnet in $(jq -c '.vpc[]?.subnets[]?[] | .[] | select(.attachPublicGateway == "true")' ${configFile} | tr -d '\r'); do
    subnet_id=$(echo ${subnet} | jq -r '.id | select (.!=null)')
    detached_pgw_id=$(echo ${subnet} | jq -r '.detached_pgw_id | select (.!=null)')

    if [ ! -z "${subnet_id}" ] && [ -z "${detached_pgw_id}" ]; then
        set +o errexit
        detachSubnetPublicGateway
        [ $? -ne 0 ] && log_error "${BASH_SOURCE[0]}: detachSubnetPublicGateway returned with an error." && exit 1
        set -o errexit
    fi
done

# VPC Infrastructure - Delete VSI
for vsi_list in $(jq -c '.vpc[]?.virtual_server_instances[]?' ${configFile} | tr -d '\r'); do
    instance_id=$(echo ${vsi_list} | jq -r '.id | select (.!=null)')
    deleted_id=$(echo ${vsi_list} | jq -r '.deleted_id | select (.!=null)')
    if [ ! -z "${instance_id}" ] && [ -z "${deleted_id}" ]; then
        set +o errexit
        deleteVSI
        [ $? -ne 0 ] && log_error "${BASH_SOURCE[0]}: deleteVSI returned with an error." && exit 1
        set -o errexit
    fi
done

# VPC Infrastructure - Wait for VSI to be gone, otherwise can't remove subnets
for vsi_list in $(jq -c '.vpc[]?.virtual_server_instances[]?' ${configFile}); do
    instance_id=$(echo ${vsi_list} | jq -r '.id | select (.!=null)')
    deleted_id=$(echo ${vsi_list} | jq -r '.deleted_id | select (.!=null)')

    if [ ! -z "${instance_id}" ]; then
        set +o errexit
        deleteVSIWait
        [ $? -ne 0 ] && log_error "${BASH_SOURCE[0]}: deleteVSIWait returned with an error." && exit 1
        set -o errexit
    fi
done

# VPC Infrastructure - Wait for Load Balancer to delete, otherwise can't remove subnets
load_balancers=$(jq -c '.vpc[]?.load_balancers[]?' ${configFile} | tr -d '\r')
for load_balancer in $load_balancers; do
    load_balancer_id=$(echo ${load_balancer} | jq -r '.id | select (.!=null)')
    deleted_id=$(echo ${load_balancer} | jq -r '.deleted_id | select (.!=null)')

    if [ ! -z "${load_balancer_id}" ]; then
        set +o errexit
        deleteLoadBalancerWait
        [ $? -ne 0 ] && log_error "${BASH_SOURCE[0]}: deleteLoadBalancerWait returned with an error." && exit 1
        set -o errexit
    fi
done

#  VPC Infrastructure - Release Floating IPs
for instance_fip_nic_ids in $(jq -c '.vpc[]?.virtual_server_instances[]? | select(.floating_ip.id != null) | { fip_id: .floating_ip.id, released_id: .floating_ip.released_id, }' ${configFile}); do
    fip_id=$(echo ${instance_fip_nic_ids} | jq -r '.fip_id | select (.!=null)')
    released_id=$(echo ${instance_fip_nic_ids} | jq -r '.released_id | select (.!=null)')

    if [ ! -z ${fip_id} ] && [ -z "${released_id}" ]; then
        set +o errexit
        releaseFIP
        [ $? -ne 0 ] && log_error "${BASH_SOURCE[0]}: releaseFIP returned with an error." && exit 1
        set -o errexit
    fi
done

#  VPC Infrastructure - Delete subnets
for subnet in $(jq -c '.vpc[]?.subnets[]?[] | .[] ' ${configFile} | tr -d '\r'); do
    subnet_id=$(echo ${subnet} | jq -r '.id | select (.!=null)')
    deleted_id=$(echo ${subnet} | jq -r '.deleted_id | select (.!=null)')

    if [ ! -z "${subnet_id}" ] && [ -z "${deleted_id}" ]; then
        set +o errexit
        deleteSubnet
        [ $? -ne 0 ] && log_error "${BASH_SOURCE[0]}: deleteSubnet returned with an error." && exit 1
        set -o errexit
    fi
done

#  VPC Infrastructure - Delete Public Gateway
for gateway in $(jq -c '.vpc[]?.public_gateways[]?' ${configFile} | tr -d '\r'); do
    pgw_id=$(echo ${gateway} | jq -r '.id | select (.!=null)')
    deleted_id=$(echo ${gateway} | jq -r '.deleted_id | select (.!=null)')
    if [ ! -z "${pgw_id}" ] && [ -z "${deleted_id}" ]; then
        set +o errexit
        deletePublicGateway
        [ $? -ne 0 ] && log_error "${BASH_SOURCE[0]}: deletePublicGateway returned with an error." && exit 1
        set -o errexit
    fi
done

#  VPC Infrastructure - Delete VPC
vpcs=$(jq -c '.vpc[]? | { id: .id, deleted_id: .deleted_id }' ${configFile})
for vpc in $vpcs; do
    vpc_id=$(echo "${vpc}" | jq -r '.id | select (.!=null)')
    deleted_id=$(echo "${vpc}" | jq -r '.deleted_id | select (.!=null)')

    if [ ! -z "${vpc_id}" ] && [ -z "${deleted_id}" ]; then
        set +o errexit
        deleteVPC
        [ $? -ne 0 ] && log_error "${BASH_SOURCE[0]}: deleteVPC returned with an error." && exit 1
        set -o errexit
    fi
done

# Delete Service Instance
for service_instance in $(jq -c '.service_instances[]?' ${configFile} | tr -d '\r'); do
    service_instance_id=$(echo ${service_instance} | jq -r '.id | select (.!=null)')
    service_instance_guid=$(echo ${service_instance} | jq -r '.guid | select (.!=null)')
    service_name=$(echo ${service_instance} | jq -r '.service_name | select (.!=null)')
    deleted_id=$(echo ${service_instance} | jq -r '.deleted_id | select (.!=null)')

    # Delete Key if service_name is kms, i.e. Key Protect
    if [ "${service_name}" = "kms" ]; then 
        key_name=$(echo ${service_instance} | jq -r '.keys[0] | .name | select (.!=null)')
        key_id=$(echo ${service_instance} | jq -r '.keys[0] | .id | select (.!=null)')
        key_deleted_id=$(echo ${service_instance} | jq -r '.keys[0] | .deleted_id | select (.!=null)')

        if [ ! -z "${key_id}" ] && [ -z "${key_deleted_id}" ]; then
            set +o errexit
            deleteKeyProtectRootKey
            [ $? -ne 0 ] && log_error "${BASH_SOURCE[0]}: deleteKeyProtectRootKey returned with an error." && exit 1
            set -o errexit
        fi
    fi

    if [ ! -z "${service_instance_id}" ] && [ -z "${deleted_id}" ]; then
        set +o errexit
        deleteServiceInstance
        [ $? -ne 0 ] && log_error "${BASH_SOURCE[0]}: deleteServiceInstance returned with an error." && exit 1
        set -o errexit
    fi
done

# Delete Classic VS
for vs_list in $(jq -c '.classic_infrastructure[]?.virtual_servers[]?' ${configFile} | tr -d '\r'); do
    vs_id=$(echo ${vs_list} | jq -r '.id | select (.!=null)')
    deleted_id=$(echo ${vs_list} | jq -r '.deleted_id | select (.!=null)')

    if [ ! -z "${vs_id}" ] && [ -z "${deleted_id}" ]; then
        set +o errexit
        deleteSLVirtualServer
        [ $? -ne 0 ] && log_error "${BASH_SOURCE[0]}: deleteSLVirtualServer returned with an error." && exit 1
        set -o errexit
    fi
done

# if post-build script found run it.
if [ -f "${config_template_file_dir}/post-delete.sh" ]; then
    set +o errexit
    . ${config_template_file_dir}/post-delete.sh
    set -o errexit
fi

log_info "${BASH_SOURCE[0]}: Completed delete."

exit 0