#!/bin/bash

# Delete the vpc image created, the cos image object and the downloaded files.
# It reverses the actions of 030-provision-vpc-vsi.sh

# include configuration variables shared by image create and image cleanup
source $(dirname "$0")/$IMAGE_VARIABLE_FILE

echo ">>> Delete custom image $IMAGE_NAME ..."
imageId=$(ibmcloud is images --output json | jq -r '.[]|select(.name=="'$IMAGE_NAME'")|.id')
if [ x$imageId == x ]; then
  echo Custom image $IMAGE_NAME not found
else
  ibmcloud is image-delete $imageId -f
fi

echo ">>> Delete qcow2 file from cos: $KEY_FILE ..."
ibmcloud cos object-delete --bucket $COS_BUCKET_NAME --key $KEY_FILE --force

echo ">>> Delete downloaded qcow2 file $DOWNLOAD_FILE.img..."
rm -f $DOWNLOAD_FILE
rm -f $KEY_FILE

echo ">>> Delete index file..."
rm -f $INDEX


