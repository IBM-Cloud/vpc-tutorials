#!/bin/bash

function version_gt() { test "$(echo "$@" | tr " " "\n" | sort -V | head -n 1)" != "$1"; }
function version_le() { test "$(echo "$@" | tr " " "\n" | sort -V | head -n 1)" == "$1"; }
function version_lt() { test "$(echo "$@" | tr " " "\n" | sort -rV | head -n 1)" != "$1"; }
function version_ge() { test "$(echo "$@" | tr " " "\n" | sort -rV | head -n 1)" == "$1"; }

function checkUpdates {
    # check the version of the ibmcloud cli and throws an error if it does not meet the minimum version requirements for this script
    log_error "${FUNCNAME[0]}: ibmcloud is not the required version"
    return 1
}

function verifyPlugin {
    # check the presences and version of the plugins required for this script
    # throws an error if it does not meet the minimum version requirements for this script.

    log_info "${FUNCNAME[0]}: ibmcloud plugin show $1"
    version=$(ibmcloud plugin show $1 | grep "Plugin Version" | awk '{ print $3 }')
    [ $? -ne 0 ] && log_error "${FUNCNAME[0]}: $1 plugin not installed and is required, please install it by running ibmcloud plugin install $1." && return 1

    if [ -z ${version} ]; then
     log_error "${FUNCNAME[0]}: The $1 plugin is not installed and is required, please install it by running ibmcloud plugin install $1."
     return 1
    fi

    if version_lt $version $2; then
        log_error "${FUNCNAME[0]}: The $1 plugin installed version is $version and is less than the required version of $2. Please update."
        return 1
    else
        log_info "${FUNCNAME[0]}: The $1 plugin installed version is $version is acceptable."
    fi

    return 0
}

function setICTarget {
    log_info "${FUNCNAME[0]}: ibmcloud target -r ${region} -g ${resource_group}"
    ibmcloud target -r ${region} -g ${resource_group} 2>&1 >/dev/null
    [ $? -ne 0 ] && log_error "${FUNCNAME[0]}: Error in selecting region and resource group." && return 1
    return 0
}

function verifyIMS {
  local ibmcloud_target
  local ims_account

  log_info "${FUNCNAME[0]}: ibmcloud target."

  ibmcloud_target=$(ibmcloud target)
  ims_account=$(echo "${ibmcloud_target}" | grep Account: | tr -s ' ' | cut -d'>' -f2 | tr -d ' ')

  if [ -z ${ims_account} ]; then
    log_error "${FUNCNAME[0]}: Unable to find an IMS account, please login to an IBM Cloud linked account"
    return 1
  fi

  log_success "${FUNCNAME[0]}: Found IMS account ${ims_account}."

  return 0
}

function verifyVPC {
  log_info "${FUNCNAME[0]}: ibmcloud is vpcs."

  ibmcloud_is_target=$(ibmcloud is target --gen 1)
  [ $? -ne 0 ] && return 1

  ibmcloud_is_vpcs=$(ibmcloud is vpcs)
  [ $? -ne 0 ] && return 1

  log_success "${FUNCNAME[0]}: Access to VPC is allowed."

  return 0
}

function verifyCSE {
  local ibmcloud_accout_show
  local cse_enabled

  log_info "${FUNCNAME[0]}: ibmcloud account show."

  ibmcloud_accout_show=$(ibmcloud account show)
  [ $? -ne 0 ] && return 1

  cse_enabled=$(echo "${ibmcloud_accout_show}" | grep "Service Endpoint Enabled:" | tr -d ' ' | cut -d':' -f2)
  if [ ${cse_enabled} = false ]; then
    log_error "${FUNCNAME[0]}: Your account is not Service Endpoint Enabled. This scenario requires it."
    return 1
  fi

  log_success "${FUNCNAME[0]}: Access to CSE is allowed."

  return 0
}

function verifyVRF {
  local ibmcloud_accout_show
  local vrf_enabled

  log_info "${FUNCNAME[0]}: ibmcloud account show."

  ibmcloud_accout_show=$(ibmcloud account show)
  [ $? -ne 0 ] && return 1

  vrf_enabled=$(echo "${ibmcloud_accout_show}" | grep "VRF Enabled:" | tr -d ' ' | cut -d':' -f2)
  if [ ${vrf_enabled} = false ]; then
    log_error "${FUNCNAME[0]}: Your account is not VRF Enabled. This scenario requires it."
    return 1
  fi

  log_success "${FUNCNAME[0]}: Access to VRF is allowed."

  return 0
}