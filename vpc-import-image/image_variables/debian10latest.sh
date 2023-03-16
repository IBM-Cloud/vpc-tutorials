site=https://cloud.debian.org/images/cloud/buster/latest
image=debian-10-genericcloud-amd64.qcow2
export OS_NAME="debian-10-amd64"
export DOWNLOAD_FILE=$site/$image
export CHECKSUM_FILE=$site/SHA512SUMS
export CHECKSUM_FUNCTION=exact