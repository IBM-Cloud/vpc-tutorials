#!/bin/bash
# download the qcow file.  Supported files on websites:
# .qcow - perfect download and use
# .qcow.xz - file that can be uncompressed using the xz tool (must be installed on this computer)
#
# Variables:
# SITE - url to the site like https://download.freebsd.org/releases/VM-IMAGES/13.1-RELEASE/amd64/Latest/
# INDEX - index file on website
#
# Note all of the work is done in a download directory.  Partial results are kept.  rm to start over

source $(dirname "$0")/trap_begin.sh

download_directory=download.$os_name
echo ">>> creating any files in $download_directory"
mkdir -p $download_directory
(
  cd $download_directory

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
)
source $(dirname "$0")/trap_end.sh