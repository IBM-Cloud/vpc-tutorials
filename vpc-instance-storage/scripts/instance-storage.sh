#!/bin/bash
# Script used to identify non-formatted Instance Stroage disks, format and mount them.
# This script is expected to run as part of a service, but can also be executed manually if desired.
#
# (C) 2021 IBM
#
# Written by Dimitri Prosper, dimitri_prosper@us.ibm.com
#

name=instance-storage
log_file=$name.$(date +%Y%m%d_%H%M%S).log
exec 3>&1 1>>$log_file 2>&1

function log_info {
    printf "\e[1;34m$(date '+%Y-%m-%d %T') %s\e[0m\n" "$@" 1>&3
}

function log_success {
    printf "\e[1;32m$(date '+%Y-%m-%d %T') %s\e[0m\n" "$@" 1>&3
}

function log_warning {
    printf "\e[1;33m$(date '+%Y-%m-%d %T') %s\e[0m\n" "$@" 1>&3
}

function log_error {
    printf >&2 "\e[1;31m$(date '+%Y-%m-%d %T') %s\e[0m\n" "$@" 1>&3
}

# Finds Instance Storage disks that are not formatted and returns a list, i.e.L /dev/vdb, /dev/vdc, etc...
disks=$(for disk in $(lsblk -p -o NAME,TYPE,PHY-SEC,LOG-SEC,MOUNTPOINT | grep disk | grep 4096 | awk 'NR>0{print $1}');\
 do file -s $disk | grep "$disk: data" | awk 'NR==1{print $1}' | sed 's/:$//'; done)

# Initializing a counter used in scheme for naming mount points
disk_counter=0

for config_disk in $disks; do
    log_info "Running format on each identified disk: mkfs.ext4 -F $config_disk"
    mkfs.ext4 -F $config_disk

    mount_point=/data$disk_counter

    log_info "Creating directory for mount point if required: mkdir $mount_point"
    mkdir -p $mount_point
    
    log_info "Updating /etc/fstab for automatic mounting of file system on reboot, using block ID for disk"
    sed -i.bak "\@$mount_point @d" /etc/fstab
    echo UUID=`blkid -s UUID -o value $config_disk` $mount_point ext4 defaults,nofail 0 0 | tee -a /etc/fstab
    
    log_info "Updating systemd with latest configuration"
    systemctl daemon-reload

    log_info "Running mount -a"
    mount -a
    [ $? -ne 0 ] && log_error "Failed mounting of new partition, review log file $log_file." && return 1

    chmod a+w $mount_point

    log_info "Updating counter for next disk/mount point"
    disk_counter=$((disk_counter+1))
done
