#!/bin/bash

name=instance-initial-config
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

function configureServices {   

cat > "/etc/systemd/system/instance-storage.service" <<- EOF
    [Unit]
    Description=instance storage re-configure
    Requires=network.target
    [Service]
    Type=simple
    ExecStart=/usr/bin/instance-storage-service.sh
    TimeoutStopSec=60
    Restart=on-failure
    RestartSec=10
    [Install]
    WantedBy=default.target
EOF

    return 0
}


function installDiskPerfTools {

    log_info "Running apt-get update."
    apt update
    [ $? -ne 0 ] && log_error "apt-get update command execution error." && return 1
    
    log_info "Running apt-get install install ioping fio systat."
    apt install ioping fio sysstat -y
    [ $? -ne 0 ] && log_error "apt-get install command execution error." && return 1

    return 0
}

function first_boot_setup {
    log_info "Started $name server configuration from cloud-init."

    configureServices
    [ $? -ne 0 ] && log_error "Failed service configuration, review log file $log_file." && return 1

    log_info "Checking apt lock status"
    is_apt_running=$(ps aux | grep -i apt | grep lock_is_held | wc -l)
    until [ "$is_apt_running" = 0 ]; do
        log_warning "Sleeping for 30 seconds while apt lock_is_held."
        sleep 30
        
        log_info "Checking apt lock status"
        is_apt_running=$(ps aux | grep -i apt | grep lock_is_held | wc -l)
    done

    installDiskPerfTools
    [ $? -ne 0 ] && log_error "Failed disk perf tools installation, review log file $log_file." && return 1

    return 0
}

first_boot_setup
[ $? -ne 0 ] && log_error "database server setup had errors." && exit 1

exit 0