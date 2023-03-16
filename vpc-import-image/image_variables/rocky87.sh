#rocky 8.7

site=http://download.rockylinux.org/pub/rocky/8.7/images/x86_64
download_file=Rocky-8-GenericCloud-LVM-8.7-20230215.0.x86_64.qcow2

# todo capitalize os_name this
OS_NAME="rocky-linux-8-amd64"
# unique image name, check ibmcloud is images --visibility private to find the image name.  The download directory
# name and the COS bucket key name ($IMAGE_NAME.qcow2) are derived from this name
#IMAGE_NAME=custom-rocky87
# https FQN of the file to download.  A sym link will be made to $IMAGE_NAME.qcow2
DOWNLOAD_FILE=$site/$download_file
# download this file to verify checksum
CHECKSUM_FILE=$site/$download_file.CHECKSUM
# checksum algorithms
CHECKSUM_FUNCTION=exact