#!/bin/bash
set -x
sleep 60; # disks may not be mounted yet.... TODO

# step through the disks in /dev/disk/by-id and find just the data (unformatted) disks
# partition, make a file system, mount, add uuid to fstab, add a version.txt file

cd /dev/disk/by-id
for symlink in $(ls -1 virtio-* |sed -e /-part/d -e /-cloud-init/d); do
  disk=$(readlink $symlink)
  disk=$(realpath $disk)
  mount_parent=/datavolumes
  mkdir -p $mount_parent
  chmod 755 $mount_parent
  if fdisk -l $disk | grep Linux; then
    echo Disk: $disk is already partitioned
  else
    echo Partition
    # the sed is used for self documentation
    sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << ____EOF | fdisk $disk
n # new partition
p # primary partition
# default - partition #
# default - first sector
# default - last sector
w # write the partition table
____EOF
    echo mkfs
    disk_partition=${disk}1
    yes | mkfs -t ext4 $disk_partition
    uuid=$(blkid -sUUID -ovalue $disk_partition)
    mount_point=$mount_parent/$uuid
    echo add uuid $uuid to /etc/fstab
    echo "UUID=$uuid $mount_point ext4 defaults,relatime 0 0" >> /etc/fstab
    echo mount $mount_point
    mkdir -p $mount_point
    chmod 755 $mount_point
    mount $mount_point
    cat  > $mount_point/version.txt << ____EOF
    version=1
    initial_disk_partition=$disk_partition
    mount_point=$mount_point
____EOF
    echo wrote version to $mount_point/version.txt
    cat $mount_point/version.txt
    sync;sync
  fi
done
