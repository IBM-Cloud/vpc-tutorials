#!/bin/bash
set -e
set -o pipefail
this_dir=$(dirname "$0")
source $this_dir/common.sh
source $this_dir/../tests_common.sh

ssh_notstrict_config="$(cd $this_dir/../../scripts; pwd -P)"/ssh.notstrict.config
function testit() {
    LOAD_BALANCER_HOSTNAME=$(terraform output LOAD_BALANCER_HOSTNAME)
}

# https://www.terraform.io/docs/commands/environment-variables.html#tf_in_automation
export TF_IN_AUTOMATION=true

# https://www.terraform.io/docs/commands/environment-variables.html#tf_var_name
export TF_VAR_ibmcloud_api_key=$API_KEY
export TF_VAR_vpc_name=$TEST_VPC_NAME
export TF_VAR_basename="at${JOB_ID}"
export TF_VAR_resource_group_name=$RESOURCE_GROUP

# only use the first key here
export TF_VAR_ssh_keyname=$(echo $KEYS | cut -d',' -f1)

echo "Region is $REGION"

cd ./vpc-autoscale
terraform init
terraform apply --auto-approve

testit

terraform destroy --auto-approve
