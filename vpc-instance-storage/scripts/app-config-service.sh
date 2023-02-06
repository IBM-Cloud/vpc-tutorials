#!/bin/bash

# Script used to create a service on the remote instance.
#
# (C) 2021 IBM
#
# Written by Dimitri Prosper, dimitri_prosper@us.ibm.com
#
# This script is used to create a service for our very simple application `app.sh`, but could also have been a binary file.  
# This script can also be added or "combined" with an existing script to the user_data during the instance creation in the `main.tf` file if desired as shown below: 
#
# resource "ibm_is_instance" "vsi_app" {
#  count          = 1
#  <....>
#
#  user_data = templatefile("../scripts/app-config-service.sh", {})
# }
#
#

name=app-config-service
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
    Requires=network.target ${mount}
    [Service]
    Type=simple
    ExecStart=/usr/bin/app.sh
    Restart=always
    RestartSec=30
    [Install]
    WantedBy=default.target
EOF
    [ $? -ne 0 ] && return 1

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