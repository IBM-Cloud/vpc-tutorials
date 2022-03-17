#!/bin/bash
set -e
set -o pipefail
this_dir=$(dirname "$0")
source $this_dir/../tests_common.sh

ssh_notstrict_config="$(cd $this_dir/../../scripts; pwd -P)"/ssh.notstrict.config
function testit {
    # TODO Testing needs to be a bit more comprehensive and then enabled
    APP_URL=$(terraform output APP_URL)
}

function error_destroy {
  set +e
  echo "Error during apply, running destroy."
  terraform destroy --auto-approve

  exit 1
}

function terraform_apply {
  cd vpc-cockroachdb-mzr

  cp -a config-template config

  rm -rf .terraform terraform.tfstate	terraform.tfstate.backup

  terraform init -input=false
  terraform validate

  trap error_destroy ERR
  terraform apply --auto-approve

  # TODO Testing needs to be a bit more comprehensive and then enabled
  # testit
  # LB_HOSTNAME=$(terraform output -state=database-app-mzr.tfstate "lb_public_hostname")
}

# export TF_LOG=debug

# https://www.terraform.io/docs/commands/environment-variables.html#tf_in_automation
export TF_IN_AUTOMATION=true

# https://www.terraform.io/docs/commands/environment-variables.html#tf_var_name
export TF_VAR_ibmcloud_api_key=$API_KEY
export TF_VAR_resources_prefix=at-$JOB_ID
export TF_VAR_resource_group=$RESOURCE_GROUP
export TF_VAR_secrets_manager_instance_name=$SM_INSTANCE_NAME
export TF_VAR_secrets_manager_group_name=smgroup-$JOB_ID

TEST_KEY_NAME=$(ssh_key_name_for_job)
export TF_VAR_vpc_ssh_key=$TEST_KEY_NAME

echo "Region is $REGION"
export TF_VAR_vpc_region=$REGION

terraform_apply

sleep 60 # Fix for Terraform destroy error during refresh state
echo "Apply completed with success, running destroy."
terraform destroy --auto-approve