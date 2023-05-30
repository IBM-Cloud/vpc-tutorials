#!/bin/bash
set -e
set -o pipefail
this_dir=$(dirname "$0")
source $this_dir/../tests_common.sh

ssh_notstrict_config="$(cd $this_dir/../../scripts; pwd -P)"/ssh.notstrict.config
function testit {
    # TODO Testing needs to be a bit more comprehensive and then enabled
    floating_ip=$(terraform output -raw Floating_IP)

    echo "Checking if instance is ready for SSH."
    ssh -F $ssh_notstrict_config root@${floating_ip} -t 'true'
    return_value=$?
    [ $return_value -ne 0 ] && is_ssh_ready=false
    [ $return_value -eq 0 ] && is_ssh_ready=true

    until [ "$is_ssh_ready" = true ]; do
      echo "Sleeping for 30 seconds while waiting for instance to be ready for SSH."
      sleep 30
      
      echo "Checking if instance is ready for SSH."
      ssh -F $ssh_notstrict_config root@${floating_ip} -t 'true'
      return_value=$?
      [ $return_value -ne 0 ] && is_ssh_ready=false
      [ $return_value -eq 0 ] && is_ssh_ready=true
    done

    ssh -F $ssh_notstrict_config -t root@${floating_ip} "lsblk | grep /data0"
    return_value=$?
    [ $return_value -ne 0 ] && exit 1

    ssh -F $ssh_notstrict_config root@${floating_ip} -t "count=\$(ls -la /data0 | wc -l); if [[ \$count < 249 ]]; then echo \$count; else echo 0; fi"
    return_value=$?
    [ $return_value -ne 0 ] && exit 1

    return 0
}

function error_destroy {
  set +e
  echo "Error during apply, running destroy."
  terraform destroy --auto-approve
  exit 1
}

function terraform_apply {
  cd vpc-instance-storage

  # cp -a config-template config

  rm -rf .terraform terraform.tfstate	terraform.tfstate.backup

  terraform init -input=false
  terraform validate

  # trap error_destroy ERR
  terraform apply --auto-approve

}

# export TF_LOG=debug

# https://www.terraform.io/docs/commands/environment-variables.html#tf_in_automation
export TF_IN_AUTOMATION=true

export TF_VAR_byok_data_volume=false

# https://www.terraform.io/docs/commands/environment-variables.html#tf_var_name
export TF_VAR_ibmcloud_api_key=$API_KEY
export TF_VAR_resources_prefix=at-$JOB_ID
export TF_VAR_resource_group=$RESOURCE_GROUP
export TF_VAR_boot_volume_name="boot-$JOB_ID"

export TF_VAR_vpc_ssh_key=$(ssh_key_name_for_job)

echo "Region is $REGION"
export TF_VAR_vpc_region=$REGION

terraform_apply

testit

# sleep 60 # Fix for Terraform destroy error during refresh state
echo "Apply completed with success, running destroy."
terraform destroy --auto-approve