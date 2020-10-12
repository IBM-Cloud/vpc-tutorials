#!/bin/bash

name=lamp-advanced
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

function installLAMP {

    log_info "Running apt-get update."
    export DEBIAN_FRONTEND=noninteractive
    apt-get update
    [ $? -ne 0 ] && log_error "apt-get update command execution error." && return 1

    log_info "Running apt-get install lamp stack."
    apt-get install apache2 mysql-server php libapache2-mod-php php-mysql php-common php-cli -y
    [ $? -ne 0 ] && log_error "apt-get install command execution error." && return 1

    return 0
}

function first_boot_setup {
    log_info "Started $name server configuration from cloud-init."

    installLAMP
    [ $? -ne 0 ] && log_error "Failed lamp installation, review log file $log_file." && return 1

    return 0
}

first_boot_setup
[ $? -ne 0 ] && log_error "database server setup had errors." && exit 1

exit 0