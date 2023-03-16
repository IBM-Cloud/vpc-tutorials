#!/bin/bash

set -e

# download and verify the qcow file.
# Note all of the work is done in a download directory.  Partial results are kept.  rm to start over
#
# Variables:
#
# IMAGE_NAME - unique image name, check ibmcloud is images --visibility private to find the image name.  The download directory
# name and the COS bucket key name ($IMAGE_NAME.qcow2) are derived from this name
# https FQN of the file to download.  A sym link will be made to $IMAGE_NAME.qcow2
# DOWNLOAD_FILE - https FQN of the file to download.  A sym link will be made to $IMAGE_NAME.qcow2
# CHECKSUM_FILE - download this file to verify checksum
source $(dirname "$0")/trap_begin.sh

for IMAGE_NAME in $IMAGE_VARIABLES; do
  download_directory=downloads/$IMAGE_NAME
  echo ">>> creating download files in $download_directory"
  mkdir -p $download_directory
  (
    set -e
    source $(dirname "$0")/image_variables/$IMAGE_NAME.sh
    check_exports $(dirname "$0")/image_variables/template.sh
    cd $download_directory
    download_file=$(basename $DOWNLOAD_FILE)
    key_file=$IMAGE_NAME.qcow2
    checksum_file=$(basename $CHECKSUM_FILE)
    echo creating $key_file from $DOWNLOAD_FILE checking with $checksum_file from $CHECKSUM_FILE
    if [ -e $key_file ]; then
      echo ">>> Using existing symlink $key_file"
    else
      # must download file and checksum and perhaps uncompress a download file
      
      # .xz files need to be uncompressed.  The qcow file is the download file unless the file needs
      # to be uncompressed.  See below for updates to qcow_file name
      qcow_file=$download_file
      extension=${download_file##*.}
      if ! [ -e $download_file ]; then
        echo ">>> Downloading file $download_file ..."
        curl -L -s -o $download_file $DOWNLOAD_FILE
      fi
      if [ $CHECKSUM_FUNCTION != none ]; then
        if [ -e $checksum_file ]; then
          echo ">>> Using existing checksum_file file..."
        else
          echo ">>> Downloading checksum_file file..."
          curl -L -s -o $checksum_file $CHECKSUM_FILE
        fi
        output=$(sha512_wrapper --ignore-missing -c $checksum_file)
        grep -e "^$download_file" <<< "$output"
      fi
      if [ x$extension = xxz ]; then
        echo ">>> uncompress $download_file"
        # qcow_file is the download file without the .xz extension
        qcow_file=${download_file%%.xz}
        # xz command will delete the original file and keep the uncompressed file
        xz -d $download_file
      fi

      # set -e insists that key_file not created unless file is downloaded and checksumed
      ln -s $qcow_file $key_file
    fi
  )
done
source $(dirname "$0")/trap_end.sh