#!/bin/bash
set -e
set -o pipefail

# include common functions
my_dir=$(dirname "$0")
. $my_dir/../scripts/common.sh

# delete classic image
CLASSIC_ID=$(cd $my_dir/create-classic && terraform output CLASSIC_ID)
for CLASSIC_IMAGE_ID in $(ibmcloud sl image list --private | grep "${PREFIX}-${CLASSIC_ID}-image" | awk '{print $1}'); do
  ibmcloud sl image delete $CLASSIC_IMAGE_ID
done

# delete image in COS
if ! ibmcloud cos delete-object --bucket "$COS_BUCKET_NAME" --key "$PREFIX-$CLASSIC_ID-image-0.vhd" --region $COS_REGION --force; then
  echo cos "$COS_BUCKET_NAME" / "$PREFIX-$CLASSIC_ID-image-0.vhd" does not exist
fi

if [ "$TARGET_GENERATION" = "2" ]; then
  if ! ibmcloud cos delete-object --bucket "$COS_BUCKET_NAME" --key "$PREFIX-$CLASSIC_ID-image-0.qcow2" --region $COS_REGION --force; then
    echo cos "$COS_BUCKET_NAME" / "$PREFIX-$CLASSIC_ID-image-0.qcow2" does not exist
  fi
fi

if [ x$COS_BUCKET_SERVICE_KEEP = x ]; then
  if ! ibmcloud cos delete-bucket --bucket "$COS_BUCKET_NAME" --region $COS_REGION --force; then
    echo cos delete-bucket --bucket "$COS_BUCKET_NAME" --region $COS_REGION --force -- failed continuing
  fi
  COS_INSTANCE_ID=$(get_instance_id $COS_SERVICE_NAME)
  COS_GUID=$(get_guid $COS_SERVICE_NAME)
  if ! ibmcloud resource service-instance-delete $COS_INSTANCE_ID --force --recursive; then
    echo ibmcloud resource service-instance-delete $COS_INSTANCE_ID --force --recursive -- failed continuing
  fi
else
  echo not deleting bucket, not deleting COS service
fi

if [ x$VPC_IMAGE_NAME = x ]; then
  VPC_IMAGE_NAME=$(echo $PREFIX-$CLASSIC_ID-image | tr '[:upper:]' '[:lower:]')
fi

# delete classic vm and vpc vsi
export IC_TIMEOUT=900
export TF_VAR_ibmcloud_api_key=$IBMCLOUD_API_KEY
export TF_VAR_iaas_classic_username=$IAAS_CLASSIC_USERNAME
export TF_VAR_iaas_classic_api_key=$IAAS_CLASSIC_API_KEY
export TF_VAR_ssh_public_key_file=$SSH_PUBLIC_KEY
export TF_VAR_ssh_private_key_file=$SSH_PRIVATE_KEY
export TF_VAR_classic_datacenter=$DATACENTER
export TF_VAR_prefix=$PREFIX

export TF_VAR_ssh_key_name=$VPC_SSH_KEY_NAME
export TF_VAR_resource_group_name=$RESOURCE_GROUP_NAME
export TF_VAR_vsi_image_name=$VPC_IMAGE_NAME
ZONE=$(ibmcloud is zones --json | jq -r .[].name | sort | head -1)
echo "Region is $REGION, zone is $ZONE"
export TF_VAR_subnet_zone=$ZONE
if [ ! -z "$TARGET_GENERATION" ]; then
  echo "Target generation set to $TARGET_GENERATION"
  export TF_VAR_generation=$TARGET_GENERATION
fi

(cd $my_dir/create-vpc-vsi && terraform init && terraform destroy --auto-approve)
(cd $my_dir/create-vpc-ssh-key && terraform init && terraform destroy --auto-approve)
(cd $my_dir/create-classic && terraform init && terraform destroy --auto-approve)

# delete vpc image
if [ x$VPC_IMAGE_KEEP = x ]; then
  VPC_IMAGES_JSON=$(ibmcloud is images --visibility private --json)
  VPC_IMAGE_ID=$(echo $VPC_IMAGES_JSON | jq -r '.[] | select(.name=="'$VPC_IMAGE_NAME'") | .id')
  ibmcloud is image-delete $VPC_IMAGE_ID --force
fi
