#!/bin/bash
#set -ex

# Script to deploy resources for IBM Cloud Solution Tutorials
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
directory="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
filename="${directory}/$(basename "${BASH_SOURCE[0]}")"
name="$(basename ${filename} .sh)"

. ${directory}/scripts/common/_package-strings-en.sh
. ${directory}/scripts/common/_utils.sh
. ${directory}/scripts/common/_ibmcloud-cli.sh
. ${directory}/scripts/vpc/_vpc.sh
. ${directory}/scripts/vpc/_public-gateway.sh
. ${directory}/scripts/vpc/_vpn.sh
. ${directory}/scripts/vpc/_subnet.sh
. ${directory}/scripts/vpc/_security_group.sh
. ${directory}/scripts/vpc/_vsi.sh
. ${directory}/scripts/vpc/_load_balancer.sh
. ${directory}/scripts/services/_common.sh
. ${directory}/scripts/services/_key_protect.sh
. ${directory}/scripts/services/_service_credential.sh
. ${directory}/scripts/sl/_vs.sh

for arg in $@; do
  parameter=$(echo ${arg} | awk -F= '{ print $1 }')
  if [ "${parameter}" = "--dry-run" ]; then
    debug=true
  elif [ "${parameter}" = "--trace" ]; then
    set -o xtrace
    IBMCLOUD_TRACE=true
  elif [ "${parameter}" = "--createLogFile" ]; then
    createLogFile=true
elif [ "${parameter}" = "--config" ]; then
    config=true
    configFileInput=$(echo ${arg} | awk -F= '{ print $2 }')
  elif [ "${parameter}" = "--template" ]; then
    configTemplate=true
    configTemplateFile=$(echo ${arg} | awk -F= '{ print $2 }')
  elif [ "${parameter}" = "--x-use-resources-prefix" ]; then
    xResourcesPrefix=$(echo ${arg} | awk -F= '{ print $2 }')
  fi
done

config_file_dir=$(dirname "$configFileInput")
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

if [ "${config}" = "false" ]; then
  log_error "${BASH_SOURCE[0]}: ${usage_msg1}"
  exit 1
fi

if [ ! -f "${configFileInput}" ]; then
  log_error "${BASH_SOURCE[0]}: Could not find config file ${configFileInput}."
  exit 1
fi

if [ "${configTemplate}" = "false" ]; then
  log_error "${BASH_SOURCE[0]}: ${usage_msg1}"
  exit 1
fi

if [ ! -f "${configTemplateFile}" ]; then
  log_error "${BASH_SOURCE[0]}: Could not find config file ${configTemplateFile}."
  exit 1
fi

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

# Verifying jq is installed/in the path.
type jq >/dev/null 2>&1 || { log_error "${jq_missing_msg1}" "${jq_missing_msg2}"; exit 1; }

if jq -e . ${configFileInput} >/dev/null 2>&1; then
  log_info "${BASH_SOURCE[0]}: The provided configuration file ${configFileInput} was successfully parsed."
else
  log_error "${BASH_SOURCE[0]}: The provided configuration file ${configFileInput} failed parsing, please check it is a valid json."
fi

# merge the configTemplateFile into the configFile (if key/values don't exist in configFile)
configFileName="$(basename ${configFileInput} .json)"

configFile="${config_file_dir}/${configFileName}.state.json"
jq -s '.[0] + .[1]' ${configTemplateFile} ${configFileInput} > "tmp.json" && mv "tmp.json" ${configFile}

log_info "${BASH_SOURCE[0]}: Using ${configFile} to store all configuration data for build."

# if parameter x_use_resources_prefix provided, modify configFile to add the list of keys provided.
if [ ! -z ${xResourcesPrefix} ]; then
  jq -r --arg xResourcesPrefix ${xResourcesPrefix} '(. | .x_use_resources_prefix) = $xResourcesPrefix' ${configFile} > "tmp.json" && mv "tmp.json" ${configFile}
fi

# Setting resources_prefix to value provided or to a default internal value if one is not provided.
resources_prefix=$(jq -r '.resources_prefix | select (.!=null)' ${configFile})
if [ -z ${resources_prefix} ]; then
  resources_prefix=tbd
fi

# Assigning the x_use_resources_prefix from reading the configFile to be available throughout the script
x_use_resources_prefix=$(jq -r '.x_use_resources_prefix | select (.!=null)' ${configFile})
IFS=, read -ra x_use_resources_prefix_keys <<< "${x_use_resources_prefix}"
unset IFS

# Go through script dependencies
dependencies=$(jq -r '.dependencies[]? | select (.!=null)' ${configFile} | tr -d '\r')
for dependency in $dependencies; do
  case "$dependency" in
    vrf) set +o errexit
          verifyVRF
          [ $? -ne 0 ] && log_error "${BASH_SOURCE[0]}: verifyVRF returned with an error, validate the account you are using has VRF access." && exit 1
          set -o errexit
        ;;
    vpc) set +o errexit
          verifyVPC
          [ $? -ne 0 ] && log_error "${BASH_SOURCE[0]}: verifyVPC returned with an error, validate the account you are using has VPC access." && exit 1
          set -o errexit
        ;;
    cse) set +o errexit
          verifyCSE
          [ $? -ne 0 ] && log_error "${BASH_SOURCE[0]}: verifyCSE returned with an error, validate the account you are using has CSE access." && exit 1
          set -o errexit
        ;;
    ims)  set +o errexit
          verifyIMS
          [ $? -ne 0 ] && log_error "${BASH_SOURCE[0]}: verifyIMS returned with an error." && exit 1
          set -o errexit
          ;;
    *) echo " $dependency : Not processed"
        ;;
  esac
done

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

region_config=$(jq -r '.region' ${configFile})
set +o errexit
addZones
[ $? -ne 0 ] && log_error "${BASH_SOURCE[0]}: addZones returned with an error." && exit 1
set -o errexit

log_info "${BASH_SOURCE[0]}: Completed validations and zones configuration, ready for build."

# Create local folder where to keep locally generated files
mkdir -p "${config_template_file_dir}/local"

# if pre-build script found run it.
if [ -f "${config_template_file_dir}/pre-build.sh" ]; then
    set +o errexit
    . ${config_template_file_dir}/pre-build.sh
    set -o errexit
fi

log_info "${BASH_SOURCE[0]}: Starting execution of ${scriptname[0]} ${scriptversion}."

# Classic Infrastructure - Create Virtual Server(s)
vss=$(jq -c '.classic_infrastructure[]?.virtual_servers[]?' ${configFile})
for vs in $vss; do
  vs_name_temp=$(echo ${vs} | jq -r '.name | select (.!=null)')
  vs_domain=$(echo ${vs} | jq -r '.domain | select (.!=null)')
  vs_os=$(echo ${vs} | jq -r '.os | select (.!=null)')
  vs_disk=$(echo ${vs} | jq -r '.disk | select (.!=null)')
  vs_nic=$(echo ${vs} | jq -r '.nic | select (.!=null)')
  vs_billing=$(echo ${vs} | jq -r '.billing | select (.!=null)')
  vs_type=$(echo ${vs} | jq -r '.type | select (.!=null)')
  vs_cpu=$(echo ${vs} | jq -r '.cpu | select (.!=null)')
  vs_memory=$(echo ${vs} | jq -r '.memory | select (.!=null)')
  vs_datacenter=$(echo ${vs} | jq -r '.datacenter | select (.!=null)')
  
  if [ ! -z ${vs_name_temp} ] && [ ! -z ${vs_domain} ] && [ ! -z ${vs_os} ] && [ ! -z ${vs_disk} ] && [ ! -z ${vs_nic} ] && [ ! -z ${vs_billing} ] && [ ! -z ${vs_cpu} ] && [ ! -z ${vs_memory} ] && [ ! -z ${vs_datacenter} ]; then
    vs_name=${resources_prefix}-${vs_name_temp}
    for x_use_resources_prefix_key in "${x_use_resources_prefix_keys[@]}"; do
      if [ "${x_use_resources_prefix_key}" = "virtual_servers" ]; then
        vs_name=${vs_name_temp}
      fi
    done

    set +o errexit
    createSLVirtualServer
    [ $? -ne 0 ] && log_error "${BASH_SOURCE[0]}: createSLVirtualServer returned with an error." && exit 1
    set -o errexit
  fi
done

# Services - Create Service (Key Protect, COS, ICD ...)
service_instances=$(jq -c '.service_instances[]?' ${configFile} | tr -d '\r')
for service_instance in $service_instances; do
  service_instance_name_temp=$(echo ${service_instance} | jq -r '.name | select (.!=null)')
  service_plan_name=$(echo ${service_instance} | jq -r '.service_plan_name | select (.!=null)')
  service_name=$(echo ${service_instance} | jq -r '.service_name | select (.!=null)')
  service_endpoints=$(echo ${service_instance} | jq -r '.service_endpoints | select (.!=null)')
  
  if [ ! -z ${service_instance_name_temp} ] && [ ! -z ${service_plan_name} ]; then
    service_instance_name=${resources_prefix}-${service_instance_name_temp}
    for x_use_resources_prefix_key in "${x_use_resources_prefix_keys[@]}"; do
      if [ "${x_use_resources_prefix_key}" = "service_instances" ]; then
        service_instance_name=${service_instance_name_temp}
      fi
    done

    set +o errexit
    createServiceInstance
    [ $? -ne 0 ] && log_warning "${BASH_SOURCE[0]}: Unable to create service instance ${service_name} ${service_instance_name}."
    
    # used to work with services that make use of service credentials, i.e. Cloud Object Storage. Only one key is supported today.
    service_key_name=$(echo ${service_instance} | jq -r '.service_credentials[0]? | .name | select (.!=null)')
    service_key_role=$(echo ${service_instance} | jq -r '.service_credentials[0]? | .role | select (.!=null)')
    service_crn=$(jq -r --arg service_instance_name_temp ${service_instance_name_temp} '.service_instances[]? | select(.name == $service_instance_name_temp) | .crn' ${configFile})

    if [ ! -z ${service_key_name} ] && [ ! -z ${service_crn} ]; then
      createServiceCredential
      [ $? -ne 0 ] && log_error "${BASH_SOURCE[0]}: Unable to create service credential ${service_key_name}." && exit 1
    fi

    # used to work with services that make use of Key Protect, i.e. Block Storage. Only one key is supported today.
    key_name=$(echo ${service_instance} | jq -r '.keys[0]? | .name | select (.!=null)')
    service_instance_id=$(jq -r --arg service_instance_name_temp ${service_instance_name_temp} '.service_instances[]? | select(.name == $service_instance_name_temp) | .guid' ${configFile})
    if [ ! -z ${key_name} ] && [ ! -z ${service_instance_id} ]; then
      createKeyProtectRootKey
      [ $? -ne 0 ] && log_error "${BASH_SOURCE[0]}: Unable to create Key Protect encryption key." && exit 1

      source_service_name=$(echo ${service_instance} | jq -r '.authorizations[0].service_name')
      source_service_role=$(echo ${service_instance} | jq -r '.authorizations[0].roles[0].name')

      if [ ! -z ${source_service_name} ] && [ ! -z ${source_service_role} ]; then
        createAuthorization
        [ $? -ne 0 ] && log_error "${BASH_SOURCE[0]}: Unable to create authorization." && exit 1
      fi
    fi
    set -o errexit
  else
    log_warning "${BASH_SOURCE[0]}: A key protect service was not specified, this script will not create any vsi that require a data_volume without a key_protect key."
  fi
done

# VPC Infrastructure - Create VPC
vpc_name_temp=$(jq -r '.vpc[]?.name' ${configFile} | tr -d '\r')
if [ ! -z ${vpc_name_temp} ]; then
  vpc_name=${resources_prefix}-${vpc_name_temp}
  for x_use_resources_prefix_key in "${x_use_resources_prefix_keys[@]}"; do
    if [ "${x_use_resources_prefix_key}" = "vpc" ]; then
      vpc_name=${vpc_name_temp}
    fi
  done

  set +o errexit
  createVPC
  [ $? -ne 0 ] && log_error "${BASH_SOURCE[0]}: createVPC returned with an error." && exit 1
  set -o errexit
fi

# VPC Infrastructure - Create Public Gateway(s)
gateways=$(jq -r '.vpc[]?.public_gateways[]?.name' ${configFile} | tr -d '\r')
for gateway in $gateways; do
    gateway_zone=$(jq -r --arg gateway ${gateway} '.vpc[].public_gateways[]? | select(.name == $gateway) | .zone | select (.!=null)' ${configFile} | tr -d '\r')
    set +o errexit
    howmany "$gateway_zone"
    [ $? -ne 0 ] && log_error "Your configuration file includes the same gateway name ${gateway} for multiple zones and that is not allowed. Please modify your ${configFile}." && exit 1
    set -o errexit

    if [ ! -z ${gateway} ] && [ ! -z ${gateway_zone} ]; then
      gateway_name_temp=${gateway}

      gateway_name=${resources_prefix}-${gateway_name_temp}
      for x_use_resources_prefix_key in "${x_use_resources_prefix_keys[@]}"; do
        if [ "${x_use_resources_prefix_key}" = "public_gateways" ]; then
          gateway_name=${gateway_name_temp}
        fi
      done

      set +o errexit
      createPublicGateway
      [ $? -ne 0 ] && log_error "${BASH_SOURCE[0]}: createPublicGateway returned with an error." && exit 1
      set -o errexit
    fi
done

# VPC Infrastructure - Create Subnet(s)
subnets=$(jq -r '.vpc[]?.subnets[]?[] | .[] | .name' ${configFile} | tr -d '\r')
for subnet in $subnets; do
  subnet_zone=$(jq -r --arg subnet ${subnet} '.vpc[].subnets[][] | .[] | select(.name == $subnet) | .zone | select (.!=null)' ${configFile})

  set +o errexit
  howmany "$subnet_zone"
  [ $? -ne 0 ] && log_error "Your configuration file includes the same subnet name for multiple zones and that is not allowed. Please modify your ${configFile}." && exit 1
  set -o errexit

  subnetIpv4AddressCount=$(jq -r --arg subnet ${subnet} '.vpc[].subnets[][] | .[] | select(.name == $subnet) | .ipv4AddressCount | select (.!=null)' ${configFile})
  subnetAttachPublicGateway=$(jq -r --arg subnet ${subnet} '.vpc[].subnets[][] | .[] | select(.name == $subnet) | .attachPublicGateway | select (.!=null)' ${configFile})

  if [ ! -z ${subnet} ] && [ ! -z ${subnet_zone} ] && [ ! -z ${subnetIpv4AddressCount} ]; then
    subnet_name_temp=${subnet}

    subnet_name=${resources_prefix}-${subnet_name_temp}
    for x_use_resources_prefix_key in "${x_use_resources_prefix_keys[@]}"; do
      if [ "${x_use_resources_prefix_key}" = "subnets" ]; then
        subnet_name=${subnet_name_temp}
      fi
    done

    set +o errexit
    createSubnet
    [ $? -ne 0 ] && log_error "${BASH_SOURCE[0]}: createSubnet returned with an error." && exit 1
    set -o errexit
  fi
done

# VPC Infrastructure - Create Load Balancer(s) - Knowing the IP address and/or hostname is required in upcoming stages, pools are created later.
load_balancers=$(jq -c '.vpc[]?.load_balancers[]?' ${configFile} | tr -d '\r')
for load_balancer in $load_balancers; do
  load_balancer_name_temp=$(echo ${load_balancer} | jq -r '.name | select (.!=null)')
  load_balancer_type=$(echo ${load_balancer} | jq -r '.type | select (.!=null)')

  if [ ! -z ${load_balancer_name_temp} ]; then
    load_balancer_name=${resources_prefix}-${load_balancer_name_temp}
    for x_use_resources_prefix_key in "${x_use_resources_prefix_keys[@]}"; do
      if [ "${x_use_resources_prefix_key}" = "load_balancers" ]; then
        load_balancer_name=${load_balancer_name_temp}
      fi
    done

    set +o errexit
    createLoadBalancer
    [ $? -ne 0 ] && log_error "${BASH_SOURCE[0]}: createLoadBalancer returned with an error." && exit 1
    set -o errexit
  fi
done

# VPC Infrastructure - Create VPN(s)
vpns=$(jq -c '.vpc[]?.vpn_gateways[]?' ${configFile} | tr -d '\r')
for vpn in $vpns; do
  if [ ! -z ${vpn} ]; then
    vpn_name_temp=$(echo ${vpn} | jq -r '.name')
    vpn_primary_subnet=$(echo ${vpn} | jq -r '.primary_subnet')

    subnet_id=$(jq -r --arg vpn_primary_subnet ${vpn_primary_subnet} '(.vpc[].subnets[][] | .[] | select(.name == $vpn_primary_subnet) | .id)' ${configFile})

    vpn_name=${resources_prefix}-${vpn_name_temp}
    for x_use_resources_prefix_key in "${x_use_resources_prefix_keys[@]}"; do
      if [ "${x_use_resources_prefix_key}" = "vpn_gateways" ]; then
        vpn_name=${vpn_name_temp}
      fi
    done

    if [ ! -z ${subnet_id} ] && [ ! -z ${vpn_name} ]; then
      set +o errexit
      createVPN
      [ $? -ne 0 ] && log_error "${BASH_SOURCE[0]}: createVPN returned with an error." && exit 1

      createVPNConnection
      set -o errexit
    fi
  fi
done

# VPC Infrastructure - Create Security Group(s)
groups=$(jq -r '.vpc[]?.security_groups[]?.name' ${configFile} | tr -d '\r')
for group in $groups; do
  duplicateCheck=$(jq -r --arg group ${group} '.vpc[].security_groups[] | select(.name == $group) | .name | select (.!=null)' ${configFile})

  set +o errexit
  howmany "$duplicateCheck"
  [ $? -ne 0 ] && log_error "Your configuration file includes the same security group name multiple times and that is not allowed. Please modify your ${configFile}." && exit 1
  set -o errexit

  if [ ! -z ${group} ]; then
    security_group_name_temp=${group}

    security_group_name=${resources_prefix}-${security_group_name_temp}
    for x_use_resources_prefix_key in "${x_use_resources_prefix_keys[@]}"; do
      if [ "${x_use_resources_prefix_key}" = "security_groups" ]; then
        security_group_name=${security_group_name_temp}
      fi
    done

    set +o errexit
    createSecurityGroup
    [ $? -ne 0 ] && log_error "${BASH_SOURCE[0]}: createSecurityGroup returned with an error.$?." && exit 1
    set -o errexit
  fi
done

# VPC Infrastructure - Create Security Group Rules(s)
groups=$(jq -r '.vpc[]?.security_groups[]?.name' ${configFile} | tr -d '\r')
for group in $groups; do
  if [ ! -z ${group} ]; then
    security_group_name_temp=${group}

    security_group_name=${resources_prefix}-${security_group_name_temp}
    for x_use_resources_prefix_key in "${x_use_resources_prefix_keys[@]}"; do
      if [ "${x_use_resources_prefix_key}" = "security_groups" ]; then
        security_group_name=${security_group_name_temp}
      fi
    done

    set +o errexit
    createSecurityGroupRule
    [ $? -ne 0 ] && log_error "${BASH_SOURCE[0]}: createSecurityGroupRule returned with an error." && exit 1
    set -o errexit
  fi
done

# VPC Infrastructure - Create Virtual Server Instance(s)
vsis=$(jq -c '.vpc[]?.virtual_server_instances[]?' ${configFile})
for vsi in $vsis; do
  vsi_name_temp=$(echo ${vsi} | jq -r '.name | select (.!=null)')
  vsi_image_name=$(echo ${vsi} | jq -r '.image_name | select (.!=null)')
  vsi_profile_name=$(echo ${vsi} | jq -r '.profile_name | select (.!=null)')
  vsi_primary_subnet=$(echo ${vsi} | jq -r '.primary_subnet | select (.!=null)')
  vsi_cloud_init=$(echo ${vsi} | jq -r '.cloud_init | select (.!=null)')
  vsi_floatingip_name_temp=$(echo ${vsi} | jq -r '.floating_ip.name | select (.!=null)')
  
  vsi_cloud_init_file="$(basename ${vsi_cloud_init} .sh)"

  if [ ! -z ${vsi_name_temp} ] && [ ! -z ${vsi_image_name} ] && [ ! -z ${vsi_profile_name} ] && [ ! -z ${vsi_primary_subnet} ]; then

    duplicateCheck=$(jq -r --arg vsi_name_temp ${vsi_name_temp} '.vpc[].virtual_server_instances[] | select(.name == $vsi_name_temp) | .name | select (.!=null)' ${configFile})

    set +o errexit
    howmany "$duplicateCheck"
    [ $? -ne 0 ] && log_error "Your configuration file includes the same vsi name multiple times and that is not allowed. Please modify your ${configFile}." && exit 1
    set -o errexit

    vsi_name=${resources_prefix}-${vsi_name_temp}
    for x_use_resources_prefix_key in "${x_use_resources_prefix_keys[@]}"; do
      if [ "${x_use_resources_prefix_key}" = "virtual_server_instances" ]; then
          vsi_name=${vsi_name_temp}
      fi
    done

    set +o errexit
    createVSI
    [ $? -ne 0 ] && log_error "${BASH_SOURCE[0]}: createVSI returned with an error." && exit 1
    set -o errexit
  fi
done

# VPC Infrastructure - Wait for Virtual Server Instance(s) to be in Running state
vsis=$(jq -c '.vpc[]?.virtual_server_instances[]?' ${configFile})
for vsi in $vsis; do
  vsi_name_temp=$(echo ${vsi} | jq -r '.name | select (.!=null)')
  vsi_floatingip_name_temp=$(echo ${vsi} | jq -r '.floating_ip.name | select (.!=null)')
  
  if [ ! -z ${vsi_name_temp} ]; then
    vsi_name=${resources_prefix}-${vsi_name_temp}
    for x_use_resources_prefix_key in "${x_use_resources_prefix_keys[@]}"; do
      if [ "${x_use_resources_prefix_key}" = "virtual_server_instances" ]; then
        vsi_name=${vsi_name_temp}
      fi
    done

    set +o errexit
    createVSIWait
    [ $? -ne 0 ] && log_error "${BASH_SOURCE[0]}: createVSIWait returned with an error." && exit 1

    if [ ! -z ${vsi_floatingip_name_temp} ]; then
      vsi_floatingip_name=${resources_prefix}-${vsi_floatingip_name_temp}
      reserveFloatingIP
      [ $? -ne 0 ] && log_error "${BASH_SOURCE[0]}: reserveFloatingIP returned with an error." && exit 1
    fi
    set -o errexit
  fi
done

# log_info "${BASH_SOURCE[0]}: Pending for 120 seconds before running application init."
# sleep 120 

# Custom - Application Init
vsis=$(jq -c '.vpc[]?.virtual_server_instances[]?' ${configFile})
for vsi in $vsis; do
  vsi_name_temp=$(echo ${vsi} | jq -r '.name | select (.!=null)')
  vsi_ssh_init=$(echo ${vsi} | jq -r '.ssh_init | select (.!=null)')
  vsi_ipv4_address=$(echo ${vsi} | jq -r '.primary_network_interface.primary_ipv4_address | select (.!=null)')

  if [ ! -z ${vsi_name_temp} ] && [ ! -z $vsi_ssh_init ] && [ ! -z $vsi_ipv4_address ]; then
    vsi_name=${resources_prefix}-${vsi_name_temp}
    for x_use_resources_prefix_key in "${x_use_resources_prefix_keys[@]}"; do
      if [ "${x_use_resources_prefix_key}" = "virtual_server_instances" ]; then
        vsi_name=${vsi_name_temp}
      fi
    done

    if [ -f "${config_template_file_dir}/ssh-init/${vsi_ssh_init}" ]; then
      set +o errexit
      . ${config_template_file_dir}/ssh-init/${vsi_ssh_init}
      [ $? -ne 0 ] && log_error "${BASH_SOURCE[0]}: ${config_template_file_dir}/ssh-init/${vsi_ssh_init} returned with an error." && exit 1
      set -o errexit
    fi
  fi
done

# VPC Infrastructure - Create Load Balancer Pool(s)
load_balancers=$(jq -c '.vpc[]?.load_balancers[]?' ${configFile} | tr -d '\r')
for load_balancer in $load_balancers; do
  load_balancer_name_temp=$(echo ${load_balancer} | jq -r '.name | select (.!=null)')
  load_balancer_type=$(echo ${load_balancer} | jq -r '.type | select (.!=null)')

  if [ ! -z ${load_balancer_name_temp} ]; then
    load_balancer_name=${resources_prefix}-${load_balancer_name_temp}
    for x_use_resources_prefix_key in "${x_use_resources_prefix_keys[@]}"; do
      if [ "${x_use_resources_prefix_key}" = "load_balancers" ]; then
        load_balancer_name=${load_balancer_name_temp}
      fi
    done

    set +o errexit
    createLoadBalancerWait
    [ $? -ne 0 ] && log_error "${BASH_SOURCE[0]}: createLoadBalancerWait returned with an error." && exit 1
    
    pools=$(jq -c --arg load_balancer_name_temp ${load_balancer_name_temp} '.vpc[].load_balancers[] | select(.name == $load_balancer_name_temp) | .pools[]?' ${configFile} | tr -d '\r')
    for pool in $pools; do
      pool_name=$(echo ${pool} | jq -r '.name | select (.!=null)')
      pool_algorithm=$(echo ${pool} | jq -r '.algorithm | select (.!=null)')
      pool_protocol=$(echo ${pool} | jq -r '.protocol | select (.!=null)')
      health_monitor_delay=$(echo ${pool} | jq -r '.health_monitor.delay | select (.!=null)')
      health_monitor_max_retries=$(echo ${pool} | jq -r '.health_monitor.max_retries | select (.!=null)')
      health_monitor_timeout=$(echo ${pool} | jq -r '.health_monitor.timeout | select (.!=null)')
      health_monitor_type=$(echo ${pool} | jq -r '.health_monitor.type | select (.!=null)')
      health_monitor_url_path=$(echo ${pool} | jq -r '.health_monitor.url_path | select (.!=null)')
      health_monitor_port=$(echo ${pool} | jq -r '.health_monitor.port | select (.!=null)')

      if [ ! -z ${pool_name} ] && [ ! -z ${pool_algorithm} ] && [ ! -z ${pool_protocol} ] && [ ! -z ${health_monitor_delay} ] && [ ! -z ${health_monitor_max_retries} ] && [ ! -z ${health_monitor_timeout} ] && [ ! -z ${health_monitor_type} ]; then
        createLoadBalancerPool
        [ $? -ne 0 ] && log_error "${BASH_SOURCE[0]}: createLoadBalancerPool returned with an error." && exit 1

        for member_list in $(jq -c --arg pool_name ${pool_name} '.vpc[].load_balancers[].pools[] | select(.name == $pool_name) | .members[]?' ${configFile}); do
          member_port=$(echo ${member_list} | jq -r '.port | select (.!=null)')
          member_name=$(echo ${member_list} | jq -r '.name | select (.!=null)')
          member_address=$(jq -r --arg member_name ${member_name} '.vpc[].virtual_server_instances[] | select(.name == $member_name) | .primary_network_interface.primary_ipv4_address | select (.!=null)' ${configFile})

          createLoadBalancerPoolMember
          [ $? -ne 0 ] && log_error "${BASH_SOURCE[0]}: createLoadBalancerPoolMember returned with an error." && exit 1
        done

        for listener_list in $(jq -c --arg load_balancer_name_temp ${load_balancer_name_temp} '.vpc[].load_balancers[] | select(.name == $load_balancer_name_temp) | .listeners[]?' ${configFile}); do
          listener_port=$(echo ${listener_list} | jq -r '.port | select (.!=null)')
          listener_protocol=$(echo ${listener_list} | jq -r '.protocol | select (.!=null)')

          createLoadBalancerListener
          [ $? -ne 0 ] && log_error "${BASH_SOURCE[0]}: createLoadBalancerListener returned with an error." && exit 1
        done
      fi
    done

    set -o errexit
  fi
done


log_info "${BASH_SOURCE[0]}: Completed execution of ${scriptname[0]} ${scriptversion}."

# if post-build script found run it.
if [ -f "${config_template_file_dir}/post-build.sh" ]; then
    set +o errexit
    . ${config_template_file_dir}/post-build.sh
    [ $? -ne 0 ] && log_error "${BASH_SOURCE[0]}: ${config_template_file_dir}/post-build.sh returned with an error." && exit 1

    set -o errexit
fi

exit 0