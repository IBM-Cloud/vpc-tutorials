#!/bin/bash
source $(dirname "$0")/trap_begin.sh


wait_image_available() {
  local status
  while true ; do
    status=$(ibmcloud is images --output json | jq -r '.[]|select(.name=="'$IMAGE_NAME'")|.status')
    if [ $status = available ]; then
      return;
    fi
    echo '>>>' waiting for image $IMAGE_NAME status available got $status
    sleep 2
  done
}
for IMAGE_NAME in $IMAGE_VARIABLES; do
  KEY_FILE=$IMAGE_NAME.qcow2
  download_directory=downloads/$IMAGE_NAME
  echo ">>> $download_directory download directory using files created in earlier step"
  (
    set -e
    source $(dirname "$0")/image_variables/$IMAGE_NAME.sh
    check_exports $(dirname "$0")/image_variables/template.sh
    
    if ! ibmcloud is operating-systems --output json | jq -e '.[]|select(.name=="'$OS_NAME'")' > /dev/null; then
      echo '***' invalid os_name $OS_NAME
      exit
    fi

    cd $download_directory

    echo ">>> check for existing image $IMAGE_NAME ..."
    if ibmcloud is images --output json | jq -e '.[]|select(.name=="'$IMAGE_NAME'")' > /dev/null; then
      echo ">>> using an existing image $IMAGE_NAME ..."
    else
      echo ">>> Creating a new image"
      echo ">>> Calculate md5"
      file_md5=$(md5 -r $KEY_FILE|cut -d ' ' -f 1)
      file_md5=$(openssl dgst -md5 -binary $KEY_FILE | openssl enc -base64)

      echo ">>> Upload $KEY_FILE to bucket $COS_BUCKET_NAME..."
      ibmcloud cos upload --bucket $COS_BUCKET_NAME --key $KEY_FILE --file $KEY_FILE --content-md5 $file_md5
      #echo ">>> Upload $KEY_FILE to bucket $COS_BUCKET_NAME..."
      #ibmcloud cos upload --bucket $COS_BUCKET_NAME --key $KEY_FILE --file $KEY_FILE

      echo ">>> Creating image $IMAGE_NAME ..."
      ibmcloud is image-create $IMAGE_NAME --file cos://$COS_REGION/$COS_BUCKET_NAME/$KEY_FILE --os-name $OS_NAME --output json
      vpcResourceAvailable images $IMAGE_NAME
    fi
    echo ">>> Waiting for image $IMAGE_NAME to be available"
    wait_image_available

    echo ">>> Verify $IMAGE_NAME ..."
    echo ">>> Calculate file sha256"
    file_sha256=$(sha256_wrapper $KEY_FILE|cut -d ' ' -f 1)
    echo ">>> Fetch image sha256"
    image_sha256=$(ibmcloud is images --output json | jq -r '.[]|select(.name=="'$IMAGE_NAME'")|.file.checksums.sha256')
    if [ $image_sha256 == $file_sha256 ]; then
      echo '>>>' Verified image sha256
    else
      echo '***' Verification of the image sha256 failed
      exit 1
    fi

    # todo
    #if [ x$CLOUDSHELL == xtrue ]; then
    #  echo ">>> removing $DOWNLOAD_FILE and $KEY_FILE to save space ..."
    #  rm -f $KEY_FILE $DOWNLOAD_FILE
    #fi
  )
done
source $(dirname "$0")/trap_end.sh