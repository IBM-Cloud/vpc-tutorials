#!/bin/bash
set -e
set -o pipefail

image_delete() {
  image_name=$1
  vpc_image_id=$(ibmcloud is images --json | jq -r '.[]|select(.name=="'$image_name'")|.id')
  [ x = x$vpc_image_id ] && return 0; # no image return

  # delete and wait
  ibmcloud is image-delete $vpc_image_id -f
  while ibmcloud is image $vpc_image_id >/dev/null 2>&1
  do 
      echo -n "."
      sleep 10
  done
  echo ""
}

# import COS image to VPC
echo "Importing image from COS..."
my_dir=$(dirname "$0")
CLASSIC_ID=$(cd $my_dir/create-classic && terraform output CLASSIC_ID)
if [ x$VPC_IMAGE_NAME = x ]; then
  VPC_IMAGE_NAME=$(echo $PREFIX-$CLASSIC_ID-image | tr '[:upper:]' '[:lower:]')
fi

echo "Downloading vhd from COS before conversion to qcow2... this can take a while..."
ibmcloud cos download --bucket $COS_BUCKET_NAME --key $PREFIX-$CLASSIC_ID-image-0.vhd ./$PREFIX-$CLASSIC_ID-image-0.vhd

echo "Converting vhd to qcow2..."
qemu-img convert -O qcow2 ./$PREFIX-$CLASSIC_ID-image-0.vhd ./$PREFIX-$CLASSIC_ID-image-0.qcow2

echo "Uploading qcow2 to COS... this can take a while..."
ibmcloud cos upload --bucket $COS_BUCKET_NAME --key $PREFIX-$CLASSIC_ID-image-0.qcow2 --file ./$PREFIX-$CLASSIC_ID-image-0.qcow2

image_delete $VPC_IMAGE_NAME
VPC_IMAGE_JSON=$(ibmcloud is image-create $VPC_IMAGE_NAME \
  --file "cos://$COS_REGION/$COS_BUCKET_NAME/$PREFIX-$CLASSIC_ID-image-0.qcow2" \
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
