SITE=https://download.freebsd.org/releases/VM-IMAGES/13.1-RELEASE/amd64/Latest/
image=FreeBSD-13.1-RELEASE-amd64.qcow2
DOWNLOAD_FILE=$image.xz
image_lower=$(echo $image|tr '[:upper:]' '[:lower:]')-1
image_lower=$(echo $image_lower|tr '.' '-')
KEY_FILE=custom-$image_lower.qcow2
IMAGE_NAME=custom-$image_lower
INDEX=CHECKSUM.SHA256
