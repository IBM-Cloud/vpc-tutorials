#!/bin/bash
set -e
set -o pipefail

export IC_TIMEOUT=900
export TF_VAR_ibmcloud_api_key=$IBMCLOUD_API_KEY
export TF_VAR_ssh_key_name=$VPC_SSH_KEY_NAME
export TF_VAR_resource_group_name=$RESOURCE_GROUP_NAME
export TF_VAR_prefix=$PREFIX

CLASSIC_ID=$(cd create-classic && terraform output CLASSIC_ID)
export TF_VAR_vsi_image_name=$(echo $PREFIX-$CLASSIC_ID-image | tr '[:upper:]' '[:lower:]')

ZONE=$(ibmcloud is zones --json | jq -r .[].name | sort | head -1)
echo "Region is $REGION, zone is $ZONE"
export TF_VAR_subnet_zone=$ZONE

# cleanup previous run
# (cd create-vpc-vsi && rm -rf .terraform terraform.tfstate terraform.tfstate.backup)

# create VSI
(cd create-vpc-vsi && terraform init && terraform apply --auto-approve)

VPC_VSI_IP_ADDRESS=$(cd create-vpc-vsi && terraform output VPC_VSI_IP_ADDRESS)

if curl --connect-timeout 10 http://$VPC_VSI_IP_ADDRESS; then
  echo "Classic VM successfully cloned into a VPC VSI!"
else
  echo "Can't reach the VPC VSI public IP address"
  exit 1
fi
