#!/bin/bash
set -e
set -o pipefail

# include common functions
. $(dirname "$0")/../scripts/common.sh

# delete classic image
CLASSIC_ID=$(cd create-classic && terraform output CLASSIC_ID)
CLASSIC_IMAGE_ID=$(ibmcloud sl image list --private | grep "${PREFIX}-${CLASSIC_ID}-image" | awk '{print $1}')
ibmcloud sl image delete $CLASSIC_IMAGE_ID

# delete image in COS
ibmcloud cos delete-object --bucket "$COS_BUCKET_NAME" --key "$PREFIX-$CLASSIC_ID-image-0.vhd" --region $COS_REGION --force
ibmcloud cos delete-bucket --bucket "$COS_BUCKET_NAME" --region $COS_REGION --force

COS_INSTANCE_ID=$(get_instance_id $COS_SERVICE_NAME)
COS_GUID=$(get_guid $COS_SERVICE_NAME)
ibmcloud resource service-instance-delete $COS_INSTANCE_ID --force --recursive

# delete classic vm and vpc vsi
export IC_TIMEOUT=900
export TF_VAR_ibmcloud_api_key=$IBMCLOUD_API_KEY
export TF_VAR_softlayer_username=$SOFTLAYER_USERNAME
export TF_VAR_softlayer_api_key=$SOFTLAYER_API_KEY
export TF_VAR_ssh_public_key_file=$SSH_PUBLIC_KEY
export TF_VAR_ssh_private_key_file=$SSH_PRIVATE_KEY
export TF_VAR_classic_datacenter=$DATACENTER
export TF_VAR_prefix=$PREFIX

export TF_VAR_ssh_key_name=$VPC_SSH_KEY_NAME
export TF_VAR_resource_group_name=$RESOURCE_GROUP_NAME
export TF_VAR_vsi_image_name=$(echo $PREFIX-$CLASSIC_ID-image | tr '[:upper:]' '[:lower:]')
ZONE=$(ibmcloud is zones --json | jq -r .[].name | sort | head -1)
echo "Region is $REGION, zone is $ZONE"
export TF_VAR_subnet_zone=$ZONE

(cd create-vpc-vsi && terraform destroy --auto-approve)
(cd create-classic && terraform destroy --auto-approve)

# delete vpc image
VPC_IMAGE_NAME=$(echo $PREFIX-$CLASSIC_ID-image | tr '[:upper:]' '[:lower:]')
VPC_IMAGES_JSON=$(ibmcloud is images --visibility private --json)
VPC_IMAGE_ID=$(echo $VPC_IMAGES_JSON | jq -r '.[] | select(.name=="'$VPC_IMAGE_NAME'") | .id')
ibmcloud is image-delete $VPC_IMAGE_ID --force
