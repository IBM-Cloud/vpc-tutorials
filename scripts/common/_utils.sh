#!/bin/bash

function log_info {
    if [ "${createLogFile}" = "true" ]; then 
        printf "$(date '+%Y-%m-%d %T') %s\n" "$@"
        printf "\e[1;34m$(date '+%Y-%m-%d %T') %s\e[0m\n" "$@" 1>&3
    else 
        printf "\e[1;34m$(date '+%Y-%m-%d %T') %s\e[0m\n" "$@"
    fi
}

function log_success {
    if [ "${createLogFile}" = "true" ]; then 
        printf "$(date '+%Y-%m-%d %T') %s\n" "$@"
        printf "\e[1;32m$(date '+%Y-%m-%d %T') %s\e[0m\n" "$@" 1>&3
    else 
        printf "\e[1;32m$(date '+%Y-%m-%d %T') %s\e[0m\n" "$@"
    fi
}

function log_warning {
    if [ "${createLogFile}" = "true" ]; then 
        printf "$(date '+%Y-%m-%d %T') %s\n" "$@"
        printf "\e[1;33m$(date '+%Y-%m-%d %T') %s\e[0m\n" "$@" 1>&3
    else 
        printf "\e[1;33m$(date '+%Y-%m-%d %T') %s\e[0m\n" "$@"
    fi
}

function log_error {
    if [ "${createLogFile}" = "true" ]; then 
        printf $(date '+%Y-%m-%d %T')" $@"
        printf >&2 "\e[1;31m$(date '+%Y-%m-%d %T') %s\e[0m\n" "$@" 1>&3
    else 
        printf >&2 "\e[1;31m$(date '+%Y-%m-%d %T') %s\e[0m\n" "$@"
    fi
}

function log_info_file_only {
 printf $(date '+%Y-%m-%d %T')" %s" "$@" 
}

function log_info_console_only {
  printf $(date '+%Y-%m-%d %T')"\e[1;32m %s\e[0m" "$@" 1>&3
}

function cleanup() {
  # cleaning up sensitive data
  unset Password
  cat /dev/null > ~/.bash_history && history -c
}

function howmany() {
  case $- in *f*) set -- $1;; *) set -f; set -- $1; set +f;; esac

  if [ $# -eq 1 ]; then
    return 0
  else
    return 1
  fi
  
  return 0
}

function addZones() {
    local is_regions
    local regions
    local region
    local region_name
    local region_status
    local zones
    local zone
    local zone_name
    local zone_status
    local gateways
    local gateway
    local current_zone_number
    local availability_zone
    local subnets
    local subnet

    if [ ! -z ${region_config} ]; then
        # check if a region does exist.
        log_info "${FUNCNAME[0]}: ibmcloud is regions --json."
        
        is_regions=$(ibmcloud is regions --json)
        [ $? -ne 0 ] && log_error "${FUNCNAME[0]}: Error reading list of regions." && return 1
        
        regions=$(echo "$is_regions" | jq -c '.[]?')

        for region in $regions; do
            region_name=$(echo "$region" | jq -r '.name')
            region_status=$(echo "$region" | jq -r '.status')

            if [ "${region_config}" == "${region_name}" ]; then
              log_info "${FUNCNAME[0]}: ibmcloud is zones ${region_name} --json | jq -c '.[]'"
              
              zones=$(ibmcloud is zones --json | jq -c '.[]?')
              [ $? -ne 0 ] && log_error "${FUNCNAME[0]}: Error reading list of zones from current target region ${region_name}." && return 1
          
              for zone in $zones; do
                zone_name=$(echo "$zone" | jq -r '.name')
                zone_status=$(echo "$zone" | jq -r '.status')

                zone_array+=("$zone_name")
              done
            fi
        done

        if [ "${#zone_array[@]}" -gt 0 ]; then
            IFS=$'\n' zone_array_sorted=($(sort <<<"${zone_array[*]}"))
            unset IFS
            
            # Add zones to public gateways
            # select all public gateways that do not have a zone property set
            gateways_total=$(jq '.vpc[]?.public_gateways | select(.!=null) | map(select(.zone == null)) | length' ${configFile})
            if [ ! -z $gateways_total ] && [ $gateways_total -ne 0 ] && [ $gateways_total -ne 1 ]; then 
                if (( $gateways_total % ${#zone_array[@]} != 0 )); then
                    log_error "${FUNCNAME[0]}: The configuration file specified $gateways_total public gateways, however there are ${#zone_array[@]} zones in the ${region_name} region. Either modify the number of public gateways to match or assign a zone to the public gateway in ${configFile} and run this script again."
                    return 1
                fi
            fi

            idx=0
            gateways=$(jq -r '.vpc[]?.public_gateways[]? | select(.zone == null) | .name | select(.!=null)' ${configFile} | tr -d '\r')
            for gateway in $gateways; do
                jq -r --arg gateway ${gateway} --arg zone_array_sorted ${zone_array_sorted[$idx]} '(.vpc[]?.public_gateways[]? | select(.name == $gateway) | .zone) = $zone_array_sorted' ${configFile} > "tmp.json" && mv "tmp.json" ${configFile}
                
                ((idx++))
                if [ $idx -ge ${#zone_array[@]} ]; then
                    idx=0
                fi
            done

            # Add zones to subnets
            idx=0
            until [ $idx -eq ${#zone_array[@]} ]; do
                current_zone_number=$(($idx + 1))
                availability_zone="availability_zone_$current_zone_number"
                subnets=$(jq -r --arg idx ${idx} --arg availability_zone ${availability_zone} '.vpc[]?.subnets[$idx | tonumber]?[$availability_zone]?[]? | .name | select(.!=null)' ${configFile} | tr -d '\r')
                for subnet in $subnets; do
                    jq -r --arg idx ${idx} --arg availability_zone ${availability_zone} --arg subnet ${subnet} --arg zone_array_sorted ${zone_array_sorted[$idx]} '(.vpc[].subnets[$idx | tonumber][$availability_zone][] | select(.name == $subnet) | .zone) = $zone_array_sorted' ${configFile} > "tmp.json" && mv "tmp.json" ${configFile}
                done
                ((idx++))
            done

            unset current_zone_number
            unset availability_zone
            unset subnets

            return 0
        fi
    fi
    
    return 1
}