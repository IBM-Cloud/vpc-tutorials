#!/bin/bash

# Script used to create a service on IBM Cloud VPC Virtual Server Instances.
#
# (C) 2021 IBM
#
# Written by Dimitri Prosper, dimitri_prosper@us.ibm.com
#
#
#

name=ssh-authorized-keys-config-service
log_file=/var/log/$name.$(date +%Y%m%d_%H%M%S).log
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

cat > "/etc/systemd/system/ssh-authorized-keys.service" <<- EOF
    [Unit]
    Description=SSH Keys Update Service
    [Service]
    Type=simple
    ExecStart=/usr/bin/ssh-authorized-keys.sh
    Restart=always
    RestartSec=30
    [Install]
    WantedBy=default.target
EOF
    [ $? -ne 0 ] && return 1

    return 0
}

function installTools {
  log_info "Running apt update."
  export DEBIAN_FRONTEND=noninteractive
  apt update
  [ $? -ne 0 ] && echo "apt update command execution error." && return 1

  log_info "Running apt install jq."
  apt install jq -y
  [ $? -ne 0 ] && log_error "apt install command execution error." && return 1

  return 0
}

function first_boot_setup {
    log_info "Started $name server configuration."

    installTools
    [ $? -ne 0 ] && log_error "installTools had errors." && exit 1

    configureServices
    [ $? -ne 0 ] && log_error "Failed service configuration, review log file $log_file." && return 1

    return 0
}

first_boot_setup
[ $? -ne 0 ] && log_error "server setup had errors." && exit 1

exit 0