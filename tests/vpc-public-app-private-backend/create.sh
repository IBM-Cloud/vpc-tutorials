#!/bin/bash
set -e
set -o pipefail
set -x

# deploy to first zone in the selected region
ZONE=$(ibmcloud is zones --json | jq -r .[].name | sort | head -1)
echo "Region is $REGION, zone is $ZONE"

# create the VPC that will be reused by the following scripts
ibmcloud is vpc-create $TEST_VPC_NAME
export REUSE_VPC=$TEST_VPC_NAME

./vpc-public-app-private-backend/vpc-pubpriv-create-with-bastion.sh $ZONE $KEYS at$JOB_ID- $RESOURCE_GROUP
