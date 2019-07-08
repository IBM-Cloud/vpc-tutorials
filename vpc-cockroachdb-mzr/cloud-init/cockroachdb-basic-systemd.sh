#!/bin/bash

name=cockroachdb-basic-systemd
log_file=${name}.$(date +%Y%m%d_%H%M%S).log
exec 3>&1 1>>${log_file} 2>&1

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

function installNTP {

    log_info "${FUNCNAME[0]}: Running apt-get update."
    apt-get update

    log_info "${FUNCNAME[0]}: Running apt-get install ntp."
    apt-get install ntp -y

    log_info "${FUNCNAME[0]}: Stopping ntp service."
    service ntp stop

    log_info "${FUNCNAME[0]}: Modifying /etc/ntp.conf."

    cp /etc/ntp.conf /etc/ntp.conf.orig

    sed -i '/pool /s/^/#/g' /etc/ntp.conf
    sed -i '/server /s/^/#/g' /etc/ntp.conf

cat >> /etc/ntp.conf <<- EOF
server time.adn.networklayer.com iburst
EOF

    log_info "${FUNCNAME[0]}: Starting ntp service."
    service ntp start

    return 0
}

function installCockroachDB {
    local app_url=https://binaries.cockroachdb.com
    local app_binary_archive=cockroach-v2.1.6.linux-amd64.tgz
    local app_binary=cockroach
    local app_user=cockroach
    local app_directory=cockroach-v2.1.6.linux-amd64

    log_info "${FUNCNAME[0]}: wget --quiet --no-clobber --output-document=${app_binary_archive} ${app_url}/${app_binary_archive}."
    wget --quiet --no-clobber --output-document=${app_binary_archive} ${app_url}/${app_binary_archive}
    [ $? -ne 0 ] && log_error "${FUNCNAME[0]}: File not found" && exit 1
    tar xvf ${app_binary_archive}
    cp ${app_directory}/${app_binary} /usr/local/bin
    rm -rf ${app_directory}

    log_info "${FUNCNAME[0]}: mkdir /var/lib/cockroach."
    mkdir /var/lib/cockroach

    log_info "${FUNCNAME[0]}: useradd ${app_user}."
    useradd ${app_user}

    log_info "${FUNCNAME[0]}: chown ${app_user} /var/lib/cockroach."
    chown ${app_user} /var/lib/cockroach

    log_info "${FUNCNAME[0]}: mkdir /data/cockroach"
    mkdir /data/cockroach

    log_info "${FUNCNAME[0]}: chown cockroach /data/cockroach"
    chown cockroach /data/cockroach

    log_info "${FUNCNAME[0]}: mkdir /data/certs"
    mkdir /data/certs

    log_info "${FUNCNAME[0]}: chown cockroach /data/certs"
    chown cockroach /data/certs

    return 0
}

function configureNewDisk {
   # Verify a new disk is available
    log_info "${FUNCNAME[0]}: getting new disk."
    # new_bsv=$(parted -l | grep "Disk $(echo $(parted -l 2>&1) | awk 'NR==1{print $2}' | sed 's/:$//')")
    new_bsv=$(echo $(parted -l 2>&1) | awk 'NR==1{print $2}' | sed 's/:$//')
    [ -z "${new_bsv}" ] && log_error "${FUNCNAME[0]}: The expected block storage volume was not found." && return 1
    
    bsv_verify=$(parted -l | grep "Disk $(echo ${new_bsv})")
    [ -z "${bsv_verify}" ] && log_error "${FUNCNAME[0]}: The expected block storage volume was not found." && return 1

    log_info "${FUNCNAME[0]}: got new disk ${new_bsv}."

    # Create a partition on the disk. (need to provide command line switches so it runs silent and not interactive)
    log_info "${FUNCNAME[0]}: Running parted ${new_bsv} mklabel gpt"
    parted ${new_bsv} mklabel gpt
    sleep 45

    log_info "${FUNCNAME[0]}: Running parted -a opt ${new_bsv} mkpart primary ext4 0% 100%"
    parted -a opt ${new_bsv} mkpart primary ext4 0% 100%
    sleep 45

    log_info "${FUNCNAME[0]}: Partition is ${new_bsv}1"
    # @todo: This is a complete hack, need to do better next time
    new_part=${new_bsv}1

    # Create the file system.
    log_info "${FUNCNAME[0]}: Running mkfs.ext4 -L cockroach-data ${new_part}"
    mkfs.ext4 -L cockroach-data ${new_part}
    sleep 15

    # Create a partition name data.
    log_info "${FUNCNAME[0]}: Running mkdir /data"
    mkdir /data

    # Mount the storage with the partition name.
    log_info "${FUNCNAME[0]}: Running mount ${new_part} /data"
    mount ${new_part} /data
    
    # Append the following line to the end of /etc/fstab (with the partition name from Step 3).
    log_info "${FUNCNAME[0]}: Adding ${new_part} to /etc/fstab"
    new_part=$(grep ${new_part} /etc/fstab)
    [ ! -z "${new_part}" ] && echo '${new_part} /data ext4 defaults,relatime 0 0' | tee -a /etc/fstab

    # mount
    log_info "${FUNCNAME[0]}: Running mount -a"
    mount -a
    [ $? -ne 0 ] && log_error "${FUNCNAME[0]}: Failed mounting of new partition, review log file ${log_file}." && return 1

    return 0
}

function first_boot_setup {
    log_info "${FUNCNAME[0]}: Started ${name} server configuration from cloud-init."

    # Fails if parted is not available. Maybe consider installing it...
    log_info "${FUNCNAME[0]}: Verifying if parted is installed."
    type parted >/dev/null 2>&1 || { log_error "${FUNCNAME[0]}: Parted is not installed, we will not be able to automate the disk configuration."; exit 1; }

    configureNewDisk
    [ $? -ne 0 ] && log_error "${FUNCNAME[0]}: Failed new disk setup, review log file ${log_file}." && exit 1

    installNTP
    [ $? -ne 0 ] && log_error "${FUNCNAME[0]}: Failed NTP installation, review log file ${log_file}." && exit 1

    installCockroachDB
    [ $? -ne 0 ] && log_error "${FUNCNAME[0]}: Failed cockroach installation, review log file ${log_file}." && exit 1

    return 0
}

first_boot_setup