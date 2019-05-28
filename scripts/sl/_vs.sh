#!/bin/bash

# @todo
# - 
# - 

function createSLVirtualServer {
    local vs_create
    local vs_id
    local vs_guid
    local vs_detail

    log_info "${FUNCNAME[0]}: ibmcloud sl vs create --hostname ${vs_name}. started."

    vs_id=$(ibmcloud sl vs list | grep ${vs_datacenter} | grep ${vs_name} | awk {'print $1'})

    if [ -z ${vs_id} ]; then

      vs_cloud_init=$(jq -r --arg vs_name_temp ${vs_name_temp} '.classic_infrastructure[]?.virtual_servers[]? | select(.name == $vs_name_temp) | .cloud_init' ${configFile})
      if [ ! -z "${vs_cloud_init}" ]; then
          p_userfile="--userfile ${config_template_file_dir}/cloud-init/${vs_cloud_init}"
      fi

      ssh_keys_name=$(jq -r '.ssh_keys[]? | select(.type == "sl") | .name' ${configFile} | tr -d '\r')
      if [ -z "${ssh_keys_name}" ]; then
          log_error "${FUNCNAME[0]}: You need to configure at least one(1) ssh key."
          return 1
      fi

      ssh_key_list=$(ibmcloud sl security sshkey-list)
      for ssh_key_name in $ssh_keys_name; do 
        ssh_key_id=$(echo "${ssh_key_list}" | grep ${ssh_key_name} | awk {'print $1'})
        if [ ! -z "${ssh_key_id}" ]; then
          jq -r --arg ssh_key_id ${ssh_key_id} --arg ssh_key_name ${ssh_key_name} '(.ssh_keys[] | select(.name == $ssh_key_name) | .id) = $ssh_key_id' ${configFile} > "tmp.json" && mv "tmp.json" ${configFile}
          p_key="${p_key} --key ${ssh_key_id}"
        fi 
      done

      vs_create=$(ibmcloud sl vs create --hostname ${vs_name} --domain ${vs_domain} --cpu ${vs_cpu} --memory ${vs_memory} --datacenter ${vs_datacenter} --os ${vs_os} --network ${vs_nic} --disk ${vs_disk} --billing ${vs_billing} ${p_userfile} ${p_key} --wait 10 --force)
      [ $? -ne 0 ] && log_error "${FUNCNAME[0]}: Error creating virtual server ${vs_name}." && log_error "${vs_create}" && return 1

      vs_id=$(echo "${vs_create}" | grep ID | awk {'print $2'})
      vs_guid=$(echo "${vs_create}" | grep guid | awk {'print $2'})

      if [ ! -z ${vs_id} ]; then
        log_success "${FUNCNAME[0]}: Created Virtual Server ${vs_name} with id ${vs_id}."

        vs_detail=$(ibmcloud sl vs detail ${vs_id})
        [ $? -ne 0 ] && log_error "Error getting vs detail for ${vs_id}." && log_error "${vs_detail}" && exit 1

        status=$(echo ${vs_detail} | awk '{for(i=1;i<=NF;i++) if ($i=="state") print $(i+1)}')

        until [ "$status" = "Running" ]; do
          log_warning "${BASH_SOURCE[0]}: sleeping for 30 seconds while vsi ${vs_id} is ${status}."
          sleep 30

          vs_detail=$(ibmcloud sl vs detail ${vs_id})
          [ $? -ne 0 ] && log_error "Error getting vs detail for ${vs_id}." && log_error "${vs_detail}" && exit 1

          status=$(echo ${vs_detail} | awk '{for(i=1;i<=NF;i++) if ($i=="state") print $(i+1)}')
        done

        ips=$(echo ${vs_detail} | awk '{for(i=1;i<=NF;i++) if ($i=="ip") print $(i+1)}')
        ips=(${ips[@]})
        vs_public_ip=${ips[0]}
        vs_private_ip=${ips[1]}

      else
        log_error "${FUNCNAME[0]}: Error creating Virtual Server ${vs_name}."
        return 1
      fi
    else
      log_warning "${FUNCNAME[0]}: Reusing Virtual Server ${vs_name} with id ${vs_id}."
    fi

    [ ! -z ${vs_id} ] && jq -r --arg vs_id ${vs_id} --arg vs_name_temp ${vs_name_temp} '(.classic_infrastructure[]?.virtual_servers[]? | select(.name == $vs_name_temp) | .id) = $vs_id' ${configFile} > "tmp.json" && mv "tmp.json" ${configFile}
    [ ! -z ${vs_guid} ] && jq -r --arg vs_guid ${vs_guid} --arg vs_name_temp ${vs_name_temp} '(.classic_infrastructure[]?.virtual_servers[]? | select(.name == $vs_name_temp) | .guid) = $vs_guid' ${configFile} > "tmp.json" && mv "tmp.json" ${configFile}
    [ ! -z ${vs_public_ip} ] && jq -r --arg vs_public_ip ${vs_public_ip} --arg vs_name_temp ${vs_name_temp} '(.classic_infrastructure[]?.virtual_servers[]? | select(.name == $vs_name_temp) | .public_ip) = $vs_public_ip' ${configFile} > "tmp.json" && mv "tmp.json" ${configFile}
    [ ! -z ${vs_private_ip} ] && jq -r --arg vs_private_ip ${vs_private_ip} --arg vs_name_temp ${vs_name_temp} '(.classic_infrastructure[]?.virtual_servers[]? | select(.name == $vs_name_temp) | .private_ip) = $vs_private_ip' ${configFile} > "tmp.json" && mv "tmp.json" ${configFile}

    log_info "${FUNCNAME[0]}: ibmcloud sl vs create --hostname ${vs_name}. done."

    return 0
}

function deleteSLVirtualServer {
    log_info "${FUNCNAME[0]}: ibmcloud sl vs cancel. started."

    ibmcloud sl vs cancel $vs_id --force
    [ $? -ne 0 ] && log_error "Error cancelling device ${vs_id}." && exit 1

    jq -r --arg vs_id ${vs_id} '(.classic_infrastructure[]?.virtual_servers[]? | select(.id == $vs_id) | .deleted_id) = $vs_id' ${configFile} > "tmp.json" && mv "tmp.json" ${configFile}

    log_info "${FUNCNAME[0]}: ibmcloud sl vs cancel. done."

    return 0
}