# ubuntu 2304
site=https://cloud-images.ubuntu.com/jammy/current/
image=jammy-server-cloudimg-amd64.img

OS_NAME="ubuntu-22-04-amd64"
DOWNLOAD_FILE=$site/$image 
CHECKSUM_FILE=$site/SHA256SUMS
CHECKSUM_FUNCTION=exact