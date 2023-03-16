# Only the upper case constants are needed

# helpers, not required
site=http://download.rockylinux.org/pub/rocky/8.7/images/x86_64
download_file=Rocky-8-GenericCloud-LVM-8.7-20230215.0.x86_64.qcow2

# 1 Name returned from `ibmcloud is oses`
export OS_NAME="rocky-linux-8-amd64"

# 3 https FQN of the file to download.  A sym link will be made to $IMAGE_NAME.qcow2 -> downloaded file
export DOWNLOAD_FILE=$site/$download_file 

# 4 download this file to verify checksum
export CHECKSUM_FILE=$site/$download_file.CHECKSUM

# 5 checksum algorithms - not used yet
export CHECKSUM_FUNCTION=exact
