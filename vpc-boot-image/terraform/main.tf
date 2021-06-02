data "ibm_resource_group" "group" {
  name = var.resource_group_name
}
data ibm_is_image "image" {
  name = var.instance_image_name
}
data ibm_is_ssh_key "ssh_key" {
  name = var.vpc_ssh_key_name
}

locals {
  tags     = []
  resource_group = data.ibm_resource_group.group
  
  name     = var.prefix
  cidr     = "10.0.0.0/16"
  zone = "${var.region}-1"
}

resource "ibm_is_vpc" "main" {
  name                      = local.name
  resource_group            = local.resource_group.id
  address_prefix_management = "manual"
  tags                      = local.tags
}
resource "ibm_is_vpc_address_prefix" "main0" {
  name     = local.name
  zone     = local.zone
  vpc      = ibm_is_vpc.main.id
  cidr     = cidrsubnet(local.cidr, 8, 0)
}
resource "ibm_is_subnet" "main0" {
  name            = local.name
  vpc             = ibm_is_vpc.main.id
  zone            = local.zone
  ipv4_cidr_block = ibm_is_vpc_address_prefix.main0.cidr
  resource_group            = local.resource_group.id
}

resource "ibm_is_security_group_rule" "inbound_all" {
  group     = ibm_is_vpc.main.default_security_group
  direction = "inbound"
  remote    = "0.0.0.0/0"
}
resource "ibm_is_security_group_rule" "outbound_all" {
  group     = ibm_is_vpc.main.default_security_group
  direction = "outbound"
  remote    = "0.0.0.0/0"
}
resource ibm_is_volume "vol0" {
  name = "${local.name}0"
  profile = "10iops-tier"
  capacity = 10
  zone           = ibm_is_subnet.main0.zone
}
resource ibm_is_volume "vol1" {
  name = "${local.name}1"
  profile = "10iops-tier"
  capacity = 11
  zone           = ibm_is_subnet.main0.zone
}
resource ibm_is_instance "main0" {
  name            = local.name
  vpc             = ibm_is_vpc.main.id
  resource_group            = local.resource_group.id
  zone           = ibm_is_subnet.main0.zone
  keys           = [data.ibm_is_ssh_key.ssh_key.id]
  image          = data.ibm_is_image.image.id
  profile        = var.profile
  volumes = [ibm_is_volume.vol0.id, ibm_is_volume.vol1.id]

  primary_network_interface {
    subnet = ibm_is_subnet.main0.id
  }
  user_data = <<-EOS
    #!/bin/bash
    set -x

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
        disk_partition=$${disk}1
        mkfs -t ext3 $disk_partition
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
      fi
    done
  EOS
}
resource ibm_is_floating_ip "main0" {
  resource_group            = local.resource_group.id
  name            = local.name
  target         = ibm_is_instance.main0.primary_network_interface[0].id
}
output resource_group_id {
  value  = local.resource_group.id
}
output vpc_id {
  value = ibm_is_vpc.main.id
}
output zone {
  value = ibm_is_subnet.main0.zone
}
output subnet_id {
  value = ibm_is_subnet.main0.id
}
output instance_id {
  value = ibm_is_instance.main0.id
}
output floating_ip {
  value = ibm_is_floating_ip.main0.address
}
output profile {
  value = var.profile
}
output key {
  value = data.ibm_is_ssh_key.ssh_key.id
}
output z {
  value = {
    ssh = "ssh root@${ibm_is_floating_ip.main0.address}"
  }
}
