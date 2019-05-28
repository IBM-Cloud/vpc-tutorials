#!/bin/bash
# ssh root@158.177.184.142 'bash -s' < browseCOS.sh

app_url=https://github.com/IBM-Cloud/vpc-tutorials
app_repo=vpc-tutorials
app_tutorial=vpc-site2site-vpn
app_directory=vpc-app-cos

name=browseCOS
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

function installBrowseCOS {
    # @todo:    Need to get the code from git that is dedicated to the app, instead of getting the entire script project. 
    #           Maybe we dedicate a repo to apps vs others for scripts

    log_info "${FUNCNAME[0]}: Running git clone ${app_url}."
    git clone ${app_url}

    log_info "${FUNCNAME[0]}: Running apt-get update."
    apt-get -qq update < /dev/null

    log_info "${FUNCNAME[0]}: Running apt-get install python python-pip."
    apt-get -qq install python python-pip -y < /dev/null

    log_info "${FUNCNAME[0]}: Running pip install -r requirements.txt."
    cd ${app_repo}/${app_tutorial}/${app_directory}
    pip install -r requirements.txt

    # log_info "${FUNCNAME[0]}: Running python browseCOS.py."
    # python browseCOS.py

    return 0
}

function first_boot_setup {
    log_info "${FUNCNAME[0]}: Started ${name} server configuration from cloud-init."

    installBrowseCOS
    [ $? -ne 0 ] && log_error "${FUNCNAME[0]}: Failed browseCOS installation, review log file ${log_file}." && exit 1
}

first_boot_setup