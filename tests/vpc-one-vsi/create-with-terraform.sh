#!/bin/bash
set -e
set -o pipefail

# https://www.terraform.io/docs/commands/environment-variables.html#tf_in_automation
export TF_IN_AUTOMATION=true

# https://www.terraform.io/docs/commands/environment-variables.html#tf_var_name
export TF_VAR_ibmcloud_api_key=$API_KEY
export TF_VAR_vpc_name=$TEST_VPC_NAME
export TF_VAR_basename="at${JOB_ID}"

# only use the first key here
export TF_VAR_ssh_keyname=$(echo $KEYS | cut -d',' -f1)

ZONE=$(ibmcloud is zones --json | jq -r .[].name | sort | head -1)
echo "Region is $REGION, zone is $ZONE"
export TF_VAR_subnet_zone=$ZONE

cd ./vpc-one-vsi/tf
terraform init
terraform apply --auto-approve
terraform destroy --auto-approve
