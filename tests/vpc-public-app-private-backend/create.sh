#!/bin/bash
set -e
set -o pipefail
this_dir=$(dirname "$0")
source $this_dir/common.sh

SSHKEYNAME=$KEYS

# deploy to first zone in the selected region
ZONE=$(ibmcloud is zones --json | jq -r .[].name | sort | head -1)
echo "Region is $REGION, zone is $ZONE"

# create the VPC that will be reused by the following scripts
ibmcloud is vpc-create $TEST_VPC_NAME --resource-group-name $RESOURCE_GROUP
export REUSE_VPC=$TEST_VPC_NAME

# provision resources
bash -x ./vpc-public-app-private-backend/vpc-pubpriv-create-with-bastion.sh $ZONE $SSHKEYNAME at$JOB_ID- $RESOURCE_GROUP resources.sh

# verify software installed
source resources.sh
test_curl $FRONT_IP_ADDRESS '' 'I am the frontend server'

ssh -F ./scripts/ssh.notstrict.config -o ProxyJump=root@$BASTION_IP_ADDRESS root@$FRONT_NIC_IP uname -a
ssh -F ./scripts/ssh.notstrict.config -o ProxyJump=root@$BASTION_IP_ADDRESS root@$FRONT_NIC_IP curl $BACK_NIC_IP
test_curl $BACK_NIC_IP "ssh -F ./scripts/ssh.notstrict.config -o ProxyJump=root@$BASTION_IP_ADDRESS root@$FRONT_NIC_IP" 'I am the backend server'
