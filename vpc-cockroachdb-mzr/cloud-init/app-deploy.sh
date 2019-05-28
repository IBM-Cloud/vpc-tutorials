#!/bin/bash

app_url=https://github.com/IBM-Cloud/vpc-tutorials.git
app_repo=vpc-tutorials
app_directory=apps/nodejs-graphql-cockroachdb

name=app
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

function installApp {
    log_info "${FUNCNAME[0]}: Running git clone ${app_url}."
    git clone ${app_url}
    git checkout experimental

    log_info "${FUNCNAME[0]}: Running apt-get update."
    apt-get -qq update < /dev/null

    log_info "${FUNCNAME[0]}: Running apt-get install nodejs."
    apt-get -qq install nodejs npm -y < /dev/null

    log_info "${FUNCNAME[0]}: Running npm install."
    cd ${app_repo}/${app_directory}
    npm install --no-optional

    log_info "${FUNCNAME[0]}: Running app build."	
    npm run build

    # log_info "${FUNCNAME[0]}: Running app."	
    # npm start

    return 0
}

function first_boot_setup {
    log_info "${FUNCNAME[0]}: Started ${name} server configuration from cloud-init."

    installApp
    [ $? -ne 0 ] && log_error "${FUNCNAME[0]}: Failed app installation, review log file ${log_file}." && exit 1
}

first_boot_setup