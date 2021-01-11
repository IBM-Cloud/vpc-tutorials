SITE=https://cloud.centos.org/centos/7/images/
image=CentOS-7-aarch64-GenericCloud-2009
DOWNLOAD_FILE=$image.qcow2
image_lower=$(echo $image|tr '[:upper:]' '[:lower:]')-1
KEY_FILE=custom-$image_lower.qcow2
IMAGE_NAME=custom-$image_lower
INDEX=sha256sum.txt
