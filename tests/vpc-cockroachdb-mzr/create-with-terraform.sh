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
  terraform destroy -state=database-app-mzr.tfstate --auto-approve
  exit 1
}

function terraform_apply {
  cd vpc-cockroachdb-mzr

  cp -a config-template config

  rm -rf .terraform database-app-mzr.tfstate database-app-mzr.tfstate.backup database-app-mzr.plan

  terraform init -input=false
  terraform validate

  terraform plan -state=database-app-mzr.tfstate -out=database-app-mzr.plan

  trap error_destroy ERR
  terraform apply -state-out=database-app-mzr.tfstate database-app-mzr.plan

  # TODO Testing needs to be a bit more comprehensive and then enabled
  # testit
  # LB_HOSTNAME=$(terraform output -state=database-app-mzr.tfstate "lb_public_hostname")
}

# https://www.terraform.io/docs/commands/environment-variables.html#tf_in_automation
export TF_IN_AUTOMATION=true

# https://www.terraform.io/docs/commands/environment-variables.html#tf_var_name
export TF_VAR_ibmcloud_api_key=$API_KEY
export TF_VAR_resources_prefix=at-$JOB_ID
export TF_VAR_generation=$TARGET_GENERATION

# only use the first key here
export TF_VAR_ssh_private_key="~/.ssh/id_rsa"
export TF_VAR_resource_group=$RESOURCE_GROUP

TEST_KEY_NAME=$(ssh_key_name_for_job)
export TF_VAR_vpc_ssh_keys=[\"$TEST_KEY_NAME\"]

echo "Region is $REGION"
export TF_VAR_vpc_region=$REGION

terraform_apply

echo "Apply completed with success, running destroy."
terraform destroy -state=database-app-mzr.tfstate --auto-approve
