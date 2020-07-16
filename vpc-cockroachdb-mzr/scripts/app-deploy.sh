#!/bin/bash

name=app-deploy
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

function installApp {
    if [ ! -f "/${app_repo}/${app_directory}/package.json" ]; then
        cd /

        log_info "Running git clone ${app_url}."
        git clone ${app_url}
    fi

        log_info "Running apt-get update."
        export DEBIAN_FRONTEND=noninteractive
        apt-get update
        [ $? -ne 0 ] && log_error "apt-get update command execution error." && return 1

        log_info "Running apt-get install nodejs."
        apt-get install nodejs npm -y
        [ $? -ne 0 ] && log_error "apt-get install command execution error." && return 1

        log_info "Running pm2 install."
        npm install pm2@latest -g
        [ $? -ne 0 ] && log_error "npm install command execution error." && return 1

        log_info "Running npm install."
        cd /${app_repo}/${app_directory}
        npm install --no-optional
        [ $? -ne 0 ] && log_error "npm install command execution error." && return 1

        log_info "Running app build."	
        npm run build
        [ $? -ne 0 ] && log_error "npm build command execution error." && return 1

    return 0
}

function configureApp {
    if [ -f "/${app_repo}/${app_directory}/package.json" ]; then

        log_info "Creating certs directory on node ${vsi_ipv4_address}."
        mkdir -p /vpc-tutorials/sampleapps/nodejs-graphql/certs
        [ $? -ne 0 ] && log_warning "cockroachdb service started with a warning on node ${vsi_ipv4_address}."

cat > "/${app_repo}/${app_directory}/config/config.json" <<- EOF
    {
    "cookie": "some_ridiculously_long_string_of_your_choice_or_keep_this_one",
    "cockroach": {
        "user": "maxroach",
        "host": "${lb_hostname}",
        "database": "bank",
        "port": 26257
    }
    }
EOF

    fi 
    return 0
}

function first_boot_setup {
    log_info "Started $name server configuration from cloud-init."

    log_info "Checking apt lock status"
    is_apt_running=$(ps aux | grep -i apt | grep lock_is_held | wc -l)
    until [ "$is_apt_running" = 0 ]; do
        log_warning "Sleeping for 30 seconds while apt lock_is_held."
        sleep 30
        
        log_info "Checking apt lock status"
        is_apt_running=$(ps aux | grep -i apt | grep lock_is_held | wc -l)
    done

    installApp
    [ $? -ne 0 ] && log_error "Failed app installation, review log file $log_file." && return 1

    configureApp
    [ $? -ne 0 ] && log_error "Failed app installation, review log file $log_file." && return 1

    return 0
}

first_boot_setup
[ $? -ne 0 ] && log_error "app-deploy had errors." && exit 1

exit 0