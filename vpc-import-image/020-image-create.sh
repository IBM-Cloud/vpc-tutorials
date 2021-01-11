#!/bin/bash
set -e
set -o pipefail

# include common functions
source $(dirname "$0")/../scripts/common.sh

# include configuration variables shared by image create and image cleanup
source $(dirname "$0")/$IMAGE_VARIABLE_FILE

echo ">>> Downloading index file..."
curl -s -o $INDEX $SITE/$INDEX

echo ">>> Downloading qcow2 file $DOWNLOAD_FILE.img..."
curl -s -o $DOWNLOAD_FILE $SITE/$DOWNLOAD_FILE
ln -s $DOWNLOAD_FILE $KEY_FILE

echo ">>> Verify downloaded file with sha256 checksum..."
egrep ".* $DOWNLOAD_FILE\$" $INDEX > /tmp/check
shasum -c /tmp/check

echo ">>> Upload $KEY_FILE to bucket $COS_BUCKET_NAME..."
ibmcloud cos upload --bucket $COS_BUCKET_NAME --key $KEY_FILE --file $KEY_FILE

echo ">>> Creating image $IMAGE_NAME ..."
ibmcloud is image-create $IMAGE_NAME --file cos://$COS_REGION/$COS_BUCKET_NAME/$KEY_FILE --os-name ubuntu-18-04-amd64 --output json
vpcResourceAvailable images $IMAGE_NAME

echo ">>> Verify $IMAGE_NAME ..."
imageId=$(ibmcloud is images --output json | jq -r '.[]|select(.name=="'$IMAGE_NAME'")|.id')
image_sha256=$(ibmcloud is image $imageId --output json | jq -r .file.checksums.sha256)
file_sha256=$(shasum -a 256 $KEY_FILE|cut -d ' ' -f 1)
if [ $image_sha256 == $file_sha256 ]; then
  echo Verified image sha256
else
  echo '***' Verification of the image sha256 failed
  exit 1
fi

