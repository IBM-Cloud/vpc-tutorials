#!/bin/bash
set -e
set -o pipefail

# import COS image to VPC
echo "Importing image from COS..."
CLASSIC_ID=$(cd create-classic && terraform output CLASSIC_ID)
VPC_IMAGE_NAME=$(echo $PREFIX-$CLASSIC_ID-image | tr '[:upper:]' '[:lower:]')
VPC_IMAGE_JSON=$(ibmcloud is image-create $VPC_IMAGE_NAME \
  --file "cos://$COS_REGION/$COS_BUCKET_NAME/$PREFIX-$CLASSIC_ID-image-0.vhd" \
  --os-name centos-7-amd64 \
  --resource-group-name $RESOURCE_GROUP_NAME --json)
VPC_IMAGE_ID=$(echo $VPC_IMAGE_JSON | jq -r .id)
# wait for image to be status=available
until ibmcloud is image $VPC_IMAGE_ID --json | jq -c -e 'select(.status=="available")' >/dev/null
do 
    echo -n "."
    sleep 10
done
echo ""

echo "Image imported into VPC"