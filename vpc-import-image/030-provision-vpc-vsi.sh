#!/bin/bash
set -e
set -o pipefail

# include configuration variables shared by image create and image cleanup
source $(dirname "$0")/$IMAGE_VARIABLE_FILE


if false; then
export TF_VAR_vsi_image_name=$IMAGE_NAME
export IC_TIMEOUT=900
export TF_VAR_ibmcloud_api_key=$IBMCLOUD_API_KEY
export TF_VAR_ssh_key_name=$VPC_SSH_KEY_NAME
export TF_VAR_resource_group_name=$RESOURCE_GROUP_NAME
export TF_VAR_prefix=$PREFIX
fi

my_dir=$(dirname "$0")

ZONE=$(ibmcloud is zones --json | jq -r .[].name | sort | head -1)
echo "Region is $REGION, zone is $ZONE"

# cleanup previous run
# (cd $my_dir/create-vpc-vsi && rm -rf .terraform terraform.tfstate terraform.tfstate.backup)

# create VSI
(
  cd $my_dir/create-vpc-vsi
  cat > terraform.tfvars <<EOF
vsi_image_name="$IMAGE_NAME"
ibmcloud_api_key="$IBMCLOUD_API_KEY"
ssh_key_name="$VPC_SSH_KEY_NAME"
resource_group_name="$RESOURCE_GROUP_NAME"
prefix="$PREFIX"
subnet_zone="$ZONE"
EOF
  terraform init
  terraform apply --auto-approve
)

VPC_VSI_IP_ADDRESS=$(cd $my_dir/create-vpc-vsi && terraform output VPC_VSI_IP_ADDRESS)

until curl http://$VPC_VSI_IP_ADDRESS; do
  sleep 1
done
