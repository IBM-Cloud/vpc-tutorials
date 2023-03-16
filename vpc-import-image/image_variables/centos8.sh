export OS_NAME="centos-7-amd64"
site=https://cloud.centos.org/centos/8/x86_64/images/
image=CentOS-8-GenericCloud-8.4.2105-20210603.0.x86_64.qcow2
export DOWNLOAD_FILE=$site/$image
export CHECKSUM_FILE=$site/CHECKSUM
export CHECKSUM_FUNCTION=exact
