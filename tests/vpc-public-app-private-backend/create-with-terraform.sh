#!/bin/bash
set -e
set -o pipefail
this_dir=$(dirname "$0")
source $this_dir/common.sh
ssh_notstrict_config="$(cd $this_dir/../../scripts; pwd -P)"/ssh.notstrict.config
function testit() {
    FRONT_IP_ADDRESS=$(terraform output FRONT_IP_ADDRESS)
    FRONT_NIC_IP=$(terraform output FRONT_NIC_IP)
    BASTION_IP_ADDRESS=$(terraform output BASTION_IP_ADDRESS)
    BACK_NIC_IP=$(terraform output BACK_NIC_IP)
    test_curl $FRONT_IP_ADDRESS '' 'I am the frontend server'
    test_curl $BACK_NIC_IP "ssh -F "$ssh_notstrict_config" -o ProxyJump=root@$BASTION_IP_ADDRESS root@$FRONT_NIC_IP" 'I am the backend server'
}

# https://www.terraform.io/docs/commands/environment-variables.html#tf_in_automation
export TF_IN_AUTOMATION=true

# https://www.terraform.io/docs/commands/environment-variables.html#tf_var_name
export TF_VAR_ibmcloud_api_key=$API_KEY
export TF_VAR_prefix=$TEST_VPC_NAME
# export TF_VAR_basename="at${JOB_ID}"

# only use the first key here
export TF_VAR_ssh_keyname=$(echo $KEYS | cut -d',' -f1)

ZONE=$(ibmcloud is zones --json | jq -r .[].name | sort | head -1)
echo "Region is $REGION, zone is $ZONE"
export TF_VAR_subnet_zone=$ZONE

cd ./vpc-public-app-private-backend/tf
terraform init
terraform apply --auto-approve

testit

terraform destroy --auto-approve

