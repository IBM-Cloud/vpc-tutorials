#!/bin/bash
set -e
set -o pipefail

(
  cd terraform
  cat > terraform.tfvars <<EOF
    ibmcloud_api_key="$IBMCLOUD_API_KEY"
    prefix="$PREFIX"
    resource_group_name="$RESOURCE_GROUP_NAME"
    region="$REGION"
    vpc_ssh_key_name="$VPC_SSH_KEY_NAME"
EOF
  terraform init
  terraform apply -auto-approve
)
