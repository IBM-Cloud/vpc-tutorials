#!/bin/bash

name=app-config
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

cat > "/etc/systemd/system/app.service" <<- EOF
    [Unit]
    Description=Simple App Service
    Requires="network.target data0.mount"
    [Service]
    Type=notify
    ExecStart=/usr/bin/app-service.sh
    TimeoutStopSec=60
    Restart=always
    RestartSec=30
    [Install]
    WantedBy=default.target
EOF

    return 0
}

function first_boot_setup {
    log_info "Started $name server configuration."

    log_info "Checking apt lock status"
    is_apt_running=$(ps aux | grep -i apt | grep lock_is_held | wc -l)
    until [ "$is_apt_running" = 0 ]; do
        log_warning "Sleeping for 30 seconds while apt lock_is_held."
        sleep 30
        
        log_info "Checking apt lock status"
        is_apt_running=$(ps aux | grep -i apt | grep lock_is_held | wc -l)
    done

    configureServices
    [ $? -ne 0 ] && log_error "Failed service configuration, review log file $log_file." && return 1

    return 0
}

first_boot_setup
[ $? -ne 0 ] && log_error "database server setup had errors." && exit 1

exit 0