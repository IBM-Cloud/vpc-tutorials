# create a symlink from the special create custom-qemu.qcow2 -> handcreated.qcow2
# ln -s /Users/pquiring/github.ibm.com/portfolio-solutions/scenario-lz-usc4/qemu/hdd.qcow2 custom-qemu.qcow2
os_name="ubuntu-22-04-amd64"
image=qemu
#DOWNLOAD_FILE=golden.qcow2
KEY_FILE=custom-$image.qcow2
IMAGE_NAME=custom-$image
#SITE=https://ziply.mm.fcix.net/fedora/linux/releases/37/Cloud/x86_64/images
#INDEX=Fedora-Cloud-37-1.7-x86_64-CHECKSUM
