#!/bin/bash
set -e
set -o pipefail
this_dir=$(dirname "$0")
source $this_dir/../tests_common.sh

# https://www.terraform.io/docs/commands/environment-variables.html#tf_in_automation
export TF_IN_AUTOMATION=true

export TF_VAR_ibmcloud_api_key=$API_KEY
export TF_VAR_iaas_classic_username=$IAAS_CLASSIC_USERNAME
export TF_VAR_iaas_classic_api_key=$IAAS_CLASSIC_API_KEY
export IC_TIMEOUT=900

TEST_KEY_NAME=$(ssh_key_name_for_job)
export TF_VAR_ssh_key_name=$TEST_KEY_NAME
export TF_VAR_resource_group_name=$RESOURCE_GROUP
export TF_VAR_generation=$TARGET_GENERATION

# generate a classic infrastructure SSH key for the test
ibmcloud sl security sshkey-add $TEST_KEY_NAME -f $HOME/.ssh/id_rsa.pub --note "created by automated tests, will be deleted"
export TF_VAR_onprem_ssh_key_name=$TEST_KEY_NAME

export TF_VAR_prefix=at$JOB_ID
export TF_VAR_vpc_name=$TEST_VPC_NAME

ZONE=$(ibmcloud is zones --json | jq -r .[].name | sort | head -1)
echo "Region is $REGION, zone is $ZONE"
export TF_VAR_region=$REGION
export TF_VAR_zone=$ZONE
export TF_VAR_onprem_datacenter=$DATACENTER

cd vpc-site2site-vpn/tf
rm -rf .terraform terraform.tfstate	terraform.tfstate.backup
terraform init
terraform apply --auto-approve
terraform destroy --auto-approve
