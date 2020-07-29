#!/bin/bash

name=cockroachdb-admin-systemd
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

function copyCerts {
  log_info "Started copyCerts."

    scp /${certs_directory}/client.maxroach.key root@${app_node1_address}:/vpc-tutorials/sampleapps/nodejs-graphql/certs/client.maxroach.key
    scp /${certs_directory}/client.maxroach.crt root@${app_node1_address}:/vpc-tutorials/sampleapps/nodejs-graphql/certs/client.maxroach.crt
    scp /${certs_directory}/ca.crt root@${app_node1_address}:/vpc-tutorials/sampleapps/nodejs-graphql/certs/ca.crt

    scp /${certs_directory}/client.maxroach.key root@${app_node2_address}:/vpc-tutorials/sampleapps/nodejs-graphql/certs/client.maxroach.key
    scp /${certs_directory}/client.maxroach.crt root@${app_node2_address}:/vpc-tutorials/sampleapps/nodejs-graphql/certs/client.maxroach.crt
    scp /${certs_directory}/ca.crt root@${app_node2_address}:/vpc-tutorials/sampleapps/nodejs-graphql/certs/ca.crt

    scp /${certs_directory}/client.maxroach.key root@${app_node3_address}:/vpc-tutorials/sampleapps/nodejs-graphql/certs/client.maxroach.key
    scp /${certs_directory}/client.maxroach.crt root@${app_node3_address}:/vpc-tutorials/sampleapps/nodejs-graphql/certs/client.maxroach.crt
    scp /${certs_directory}/ca.crt root@${app_node3_address}:/vpc-tutorials/sampleapps/nodejs-graphql/certs/ca.crt        

  return 0

}

function init_setup {

    copyCerts
    [ $? -ne 0 ] && log_error "Failed copyCerts, review log file $log_file." && return 1
    
    return 0
}

init_setup
[ $? -ne 0 ] && log_error "admin server setup had errors." && exit 1

exit 0