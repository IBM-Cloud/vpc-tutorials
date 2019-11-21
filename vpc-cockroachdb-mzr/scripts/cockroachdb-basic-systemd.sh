#!/bin/bash

name=cockroachdb-basic-systemd
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

function installNTP {

    log_info "Running apt-get update."
    apt-get update
    [ $? -ne 0 ] && log_error "apt-get update command execution error." && return 1
    
    log_info "Running apt-get install ntp."
    apt-get install ntp -y
    [ $? -ne 0 ] && log_error "apt-get install command execution error." && return 1

    log_info "Stopping ntp service."
    service ntp stop

    log_info "Modifying /etc/ntp.conf."

    cp /etc/ntp.conf /etc/ntp.conf.orig

    sed -i '/pool /s/^/#/g' /etc/ntp.conf
    sed -i '/server /s/^/#/g' /etc/ntp.conf

cat >> /etc/ntp.conf <<- EOF
server time.adn.networklayer.com iburst
EOF

    log_info "Starting ntp service."
    service ntp start

    return 0
}

function installCockroachDB {

    if [ ! -f "/usr/local/bin/${app_binary}" ]; then

        log_info "wget --quiet --no-clobber --output-document=${app_binary_archive} ${app_url}/${app_binary_archive}."
        wget --quiet --no-clobber --output-document=${app_binary_archive} ${app_url}/${app_binary_archive}
        return_value=$?
        [ $return_value -ne 0 ] && log_error "File not found: $return_value" && exit 1

        tar xvf ${app_binary_archive}
        cp ${app_directory}/${app_binary} /usr/local/bin
        rm -rf ${app_directory}

        log_info "mkdir /var/lib/cockroach."
        mkdir /var/lib/cockroach

        log_info "useradd ${app_user}."
        useradd ${app_user}

        log_info "chown ${app_user} /var/lib/cockroach."
        chown ${app_user} /var/lib/cockroach

        log_info "mkdir /data/cockroach"
        mkdir /data/cockroach

        log_info "chown cockroach /data/cockroach"
        chown cockroach /data/cockroach

        log_info "mkdir /data/certs"
        mkdir /data/certs

        log_info "chown cockroach /data/certs"
        chown cockroach /data/certs
    fi
    return 0
}

function configureNewDisk {
  if [ ! -d "/data" ]; then

    # Verify a new disk is available
        log_info "getting new disk."
        # new_bsv=$(parted -l | grep "Disk $(echo $(parted -l 2>&1) | awk 'NR==1{print $2}' | sed 's/:$//')")
        new_bsv=$(echo $(parted -l 2>&1) | awk 'NR==1{print $2}' | sed 's/:$//')
        [ -z "$${new_bsv}" ] && log_error "The expected block storage volume was not found." && return 1
        
        bsv_verify=$(parted -l | grep "Disk $(echo $${new_bsv})")
        [ -z "$${bsv_verify}" ] && log_error "The expected block storage volume was not found." && return 1

        log_info "got new disk $${new_bsv}."

        # Create a partition on the disk. (need to provide command line switches so it runs silent and not interactive)
        log_info "Running parted $${new_bsv} mklabel gpt"
        parted $${new_bsv} mklabel gpt
        sleep 45

        log_info "Running parted -a opt $${new_bsv} mkpart primary ext4 0% 100%"
        parted -a opt $${new_bsv} mkpart primary ext4 0% 100%
        sleep 45

        log_info "Partition is $${new_bsv}1"
        # @todo: This is a complete hack, need to do better next time
        new_part=$${new_bsv}1

        # Create the file system.
        log_info "Running mkfs.ext4 -L cockroach-data $${new_part}"
        mkfs.ext4 -L cockroach-data $${new_part}
        sleep 15

        # Create a partition name data.
        log_info "Running mkdir /data"
        mkdir /data

        # Mount the storage with the partition name.
        log_info "Running mount $${new_part} /data"
        mount $${new_part} /data
        
        # Append the following line to the end of /etc/fstab (with the partition name from Step 3).
        log_info "Adding $${new_part} to /etc/fstab"
        new_part=$(grep $${new_part} /etc/fstab)
        [ ! -z "$${new_part}" ] && echo '$${new_part} /data ext4 defaults,relatime 0 0' | tee -a /etc/fstab

        # mount
        log_info "Running mount -a"
        mount -a
        [ $? -ne 0 ] && log_error "Failed mounting of new partition, review log file $log_file." && return 1
    fi 
    return 0
}

function configureCockroachDB {
  if [ ! -f "${store_certs_directory}/node.key" ]; then

    ExecStart="/usr/local/bin/cockroach start --certs-dir=${store_certs_directory} --store=${store_directory} --listen-addr=${vsi_ipv4_address} --join=${join_list} --cache=.25 --max-sql-memory=.25"

    log_info "Creating cockroachdb service configuration with $ExecStart."

cat > "/etc/systemd/system/cockroachdb.service" <<- EOF
    [Unit]
    Description=Cockroach Database cluster node
    Requires=network.target
    [Service]
    Type=notify
    WorkingDirectory=/var/lib/cockroach
    ExecStart=$ExecStart
    TimeoutStopSec=60
    Restart=always
    RestartSec=10
    StandardOutput=syslog
    StandardError=syslog
    SyslogIdentifier=cockroach
    User=cockroach
    [Install]
    WantedBy=default.target
EOF

        log_info "Creating certs directory on node ${vsi_ipv4_address}."
        mkdir -p ${store_certs_directory}
        [ $? -ne 0 ] && log_warning "cockroachdb service started with a warning on node ${vsi_ipv4_address}."

    fi 
    return 0
}

function first_boot_setup {
    log_info "Started $name server configuration from cloud-init."

    # Fails if parted is not available. Maybe consider installing it...
    log_info "Verifying if parted is installed."
    type parted >/dev/null 2>&1 || { log_error "Parted is not installed, we will not be able to automate the disk configuration."; return 1; }

    configureNewDisk
    [ $? -ne 0 ] && log_error "Failed new disk setup, review log file $log_file." && return 1

    installNTP
    [ $? -ne 0 ] && log_error "Failed NTP installation, review log file $log_file." && return 1

    installCockroachDB
    [ $? -ne 0 ] && log_error "Failed cockroach installation, review log file $log_file." && return 1

    configureCockroachDB
    [ $? -ne 0 ] && log_error "Failed cockroach installation, review log file $log_file." && return 1

    return 0
}

first_boot_setup
[ $? -ne 0 ] && log_error "database server setup had errors." && exit 1

exit 0