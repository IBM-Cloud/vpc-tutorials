#!/bin/bash
set -e
set -o pipefail

export IC_TIMEOUT=900
export TF_VAR_ibmcloud_api_key=$IBMCLOUD_API_KEY
export TF_VAR_ssh_key_name=$VPC_SSH_KEY_NAME
export TF_VAR_ssh_public_key_file=$SSH_PUBLIC_KEY
export TF_VAR_resource_group_name=$RESOURCE_GROUP_NAME
export TF_VAR_prefix=$PREFIX

if [ ! -z "$TARGET_GENERATION" ]; then
  export TF_VAR_generation=$TARGET_GENERATION
fi

my_dir=$(dirname "$0")

if [ x$VPC_IMAGE_NAME = x ]; then
  CLASSIC_ID=$(cd $my_dir/create-classic && terraform output CLASSIC_ID)
  VPC_IMAGE_NAME=$(echo $PREFIX-$CLASSIC_ID-image | tr '[:upper:]' '[:lower:]')
fi
export TF_VAR_vsi_image_name=$VPC_IMAGE_NAME

ZONE=$(ibmcloud is zones --json | jq -r .[].name | sort | head -1)
echo "Region is $REGION, zone is $ZONE"
export TF_VAR_subnet_zone=$ZONE

# cleanup previous run
# (cd $my_dir/create-vpc-vsi && rm -rf .terraform terraform.tfstate terraform.tfstate.backup)

# create ssh key if none is provided
if [ x$VPC_SSH_KEY_CREATE = x ]; then
  echo not createing a vpc ssh key, using existing key $VPC_SSH_KEY_NAME
else
  (cd $my_dir/create-vpc-ssh-key && terraform init && terraform apply --auto-approve)
fi
# create VSI
(cd $my_dir/create-vpc-vsi && terraform init && terraform apply --auto-approve)

VPC_VSI_IP_ADDRESS=$(cd $my_dir/create-vpc-vsi && terraform output VPC_VSI_IP_ADDRESS)

until curl http://$VPC_VSI_IP_ADDRESS; do
  sleep 1
done
