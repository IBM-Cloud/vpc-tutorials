#!/bin/bash
set -e
set -o pipefail

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

# after being provisioned the lb receives further updates from the instance group
# and turns its status to `update_pending` before going back to `active`
# so we are going to 
n=0
until [ "$n" -ge 10 ]
do
  terraform destroy -auto-approve -target=ibm_is_instance_group.instance_group && break
  echo "failed to delete instance_group, will retry..."
  n=$((n+1))
  sleep 60
done

# leave some time for all VSIs in the group to  to delete all VSIs in the group
echo "waiting for load balancer to stabilize..."
sleep 240

# destroy the remaining resources
terraform destroy --auto-approve
