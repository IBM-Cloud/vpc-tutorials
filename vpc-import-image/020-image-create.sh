#!/bin/bash
set -e
set -o pipefail

# include common functions
source $(dirname "$0")/../scripts/common.sh

# include configuration variables shared by image create and image cleanup
source $(dirname "$0")/$IMAGE_VARIABLE_FILE

if [ -e $INDEX ]; then
  echo ">>> Using existing index file..."
else
  echo ">>> Downloading index file..."
  curl -s -o $INDEX $SITE/$INDEX
fi

if [ -e $DOWNLOAD_FILE ]; then
  echo ">>> Using existing qcow2 $DOWNLOAD_FILE..."
else
  echo ">>> Downloading qcow2 file $DOWNLOAD_FILE..."
  curl -s -o $DOWNLOAD_FILE $SITE/$DOWNLOAD_FILE
  ln -s $DOWNLOAD_FILE $KEY_FILE
fi


echo ">>> Verify downloaded file with sha256 checksum..."
egrep "$DOWNLOAD_FILE\$" $INDEX > /tmp/check
if ! sha256_wrapper -c /tmp/check; then
  echo ">>> sha256 check failed try sha512: Verify downloaded file with sha256 checksum..."
  sha512_wrapper -c /tmp/check
fi


image_sha256=$(ibmcloud is images --output json | jq -r '.[]|select(.name=="'$IMAGE_NAME'")|.file.checksums.sha256')
if [ x$image_sha256 == x ]; then
  echo ">>> Upload $KEY_FILE to bucket $COS_BUCKET_NAME..."
  ibmcloud cos upload --bucket $COS_BUCKET_NAME --key $KEY_FILE --file $KEY_FILE

  echo ">>> Creating image $IMAGE_NAME ..."
  ibmcloud is image-create $IMAGE_NAME --file cos://$COS_REGION/$COS_BUCKET_NAME/$KEY_FILE --os-name ubuntu-18-04-amd64 --output json
  vpcResourceAvailable images $IMAGE_NAME
else
  echo ">>> using existing image $IMAGE_NAME ..."
fi


echo ">>> Verify $IMAGE_NAME ..."
image_sha256=$(ibmcloud is images --output json | jq -r '.[]|select(.name=="'$IMAGE_NAME'")|.file.checksums.sha256')
file_sha256=$(sha256_wrapper $KEY_FILE|cut -d ' ' -f 1)
if [ $image_sha256 == $file_sha256 ]; then
  echo Verified image sha256
else
  echo '***' Verification of the image sha256 failed
  exit 1
fi

