#!/bin/bash
set -e
set -o pipefail

export IC_TIMEOUT=900
export TF_VAR_ibmcloud_api_key=$IBMCLOUD_API_KEY
export TF_VAR_iaas_classic_username=$IAAS_CLASSIC_USERNAME
export TF_VAR_iaas_classic_api_key=$IAAS_CLASSIC_API_KEY
export TF_VAR_ssh_public_key_file=$SSH_PUBLIC_KEY
export TF_VAR_ssh_private_key_file=$SSH_PRIVATE_KEY
export TF_VAR_classic_datacenter=$DATACENTER
export TF_VAR_prefix=$PREFIX

my_dir=$(dirname "$0")
# cleanup previous run
# (cd $my_dir/create-classic && rm -rf .terraform terraform.tfstate terraform.tfstate.backup)

# create VSI
(cd $my_dir/create-classic && terraform init && terraform apply --auto-approve)

CLASSIC_IP_ADDRESS=$(cd $my_dir/create-classic && terraform output CLASSIC_IP_ADDRESS)

if curl --connect-timeout 10 http://$CLASSIC_IP_ADDRESS; then
  echo "Classic VM is ready to be captured"
else
  echo "Can't reach the classic VM public IP address"
  exit 1
fi
