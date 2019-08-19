#!/bin/bash
set -e
set -o pipefail

export IC_TIMEOUT=900
export TF_VAR_ibmcloud_api_key=$IBMCLOUD_API_KEY
export TF_VAR_softlayer_username=$SOFTLAYER_USERNAME
export TF_VAR_softlayer_api_key=$SOFTLAYER_API_KEY
export TF_VAR_ssh_public_key_file=$SSH_PUBLIC_KEY
export TF_VAR_ssh_private_key_file=$SSH_PRIVATE_KEY
export TF_VAR_classic_datacenter=$DATACENTER
export TF_VAR_prefix=$PREFIX

# cleanup previous run
# (cd create-classic && rm -rf .terraform terraform.tfstate terraform.tfstate.backup)

# create VSI
(cd create-classic && terraform init && terraform apply --auto-approve)

CLASSIC_IP_ADDRESS=$(cd create-classic && terraform output CLASSIC_IP_ADDRESS)

if curl --connect-timeout 10 http://$CLASSIC_IP_ADDRESS; then
  echo "Classic VM is ready to be captured"
else
  echo "Can't reach the classic VM public IP address"
  exit 1
fi
