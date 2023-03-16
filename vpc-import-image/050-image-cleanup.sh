#!/bin/bash

# Delete the vpc image created, the cos image object and the downloaded files.
# It reverses the actions of 030-provision-vpc-vsi.sh

# include configuration variables shared by image create and image cleanup
source $(dirname "$0")/trap_begin.sh

for IMAGE_NAME in $IMAGE_VARIABLES; do
  key_file=$IMAGE_NAME.qcow2
  echo ">>> Delete qcow2 file from cos: $key_file ..."
  ibmcloud cos object-delete --bucket $COS_BUCKET_NAME --key $key_file --force

  echo ">>> Delete custom image $IMAGE_NAME ..."
  imageId=$(ibmcloud is images --visibility private --output json | jq -r '.[]|select(.name=="'$IMAGE_NAME'")|.id')
  if [ x$imageId == x ]; then
    echo Custom image $IMAGE_NAME not found
  else
    ibmcloud is image-delete $imageId -f
  fi
done

source $(dirname "$0")/trap_end.sh
