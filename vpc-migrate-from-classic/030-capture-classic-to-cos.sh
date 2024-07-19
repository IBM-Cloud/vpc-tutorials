#!/bin/bash
set -e
set -o pipefail

# capture image
my_dir=$(dirname "$0")

CLASSIC_ID=$(cd $my_dir/create-classic && terraform output -raw CLASSIC_ID)
image_captured_name=${PREFIX}-${CLASSIC_ID}-image

if ! [ -z $(ibmcloud sl image list --private | grep $image_captured_name | awk '{print $1}') ]; then
  echo An image with this name has already been captured, name: $image_captured_name
else
  echo "Capturing image for VSI $CLASSIC_ID..."
  ibmcloud sl vs capture $CLASSIC_ID -n $image_captured_name --note "capture of ${CLASSIC_ID}"
fi

# wait for the image to be Active
CLASSIC_IMAGE_ID=$(ibmcloud sl image list --private | grep "$image_captured_name" | awk '{print $1}')
echo "Waiting for image $CLASSIC_IMAGE_ID to be Active..."
until ibmcloud sl call-api SoftLayer_Virtual_Guest_Block_Device_Template_Group getObject --init ${CLASSIC_IMAGE_ID} --mask children | jq -c --exit-status 'select (.children[0].transactionId == null)' >/dev/null
do 
    echo -n "."
    sleep 10
done
echo ""

# copy image from classic to COS
echo "Copying image from classic to COS..."
ibmcloud sl call-api SoftLayer_Virtual_Guest_Block_Device_Template_Group copyToIcos \
  --init ${CLASSIC_IMAGE_ID} --parameters '[{"uri": "cos://'$COS_REGION'/'$COS_BUCKET_NAME'/'$image_captured_name.vhd'", "ibmApiKey": "'$IBMCLOUD_API_KEY'"}]'

echo "Waiting for the image to be ready in COS..."
until ibmcloud cos head-object --bucket "$COS_BUCKET_NAME" --key "$image_captured_name-0.vhd" --region $COS_REGION > /dev/null 2>&1
do 
    echo -n "."
    sleep 10
done
echo ""

echo "Image copied to COS"
