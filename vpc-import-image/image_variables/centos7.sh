export OS_NAME="centos-7-amd64"
site=https://cloud.centos.org/centos/7/images/
image=CentOS-7-x86_64-GenericCloud-1907.qcow2
export DOWNLOAD_FILE=$site/$image
export CHECKSUM_FILE=$site/sha256sum.txt
export CHECKSUM_FUNCTION=exact