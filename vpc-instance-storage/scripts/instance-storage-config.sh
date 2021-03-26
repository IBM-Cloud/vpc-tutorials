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


function first_boot_setup {
    log_info "Started $name server configuration."

    configureServices
    [ $? -ne 0 ] && log_error "Failed service configuration, review log file $log_file." && return 1

    return 0
}

first_boot_setup
[ $? -ne 0 ] && log_error "server setup had errors." && exit 1

exit 0