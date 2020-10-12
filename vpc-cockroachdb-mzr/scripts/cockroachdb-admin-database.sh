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

    scp /${certs_directory}/${db_node1_address}.node.key root@${db_node1_address}:/data/certs/node.key
    scp /${certs_directory}/${db_node1_address}.node.crt root@${db_node1_address}:/data/certs/node.crt
    scp /${certs_directory}/ca.crt root@${db_node1_address}:/data/certs/ca.crt

    scp /${certs_directory}/${db_node2_address}.node.key root@${db_node2_address}:/data/certs/node.key
    scp /${certs_directory}/${db_node2_address}.node.crt root@${db_node2_address}:/data/certs/node.crt
    scp /${certs_directory}/ca.crt root@${db_node2_address}:/data/certs/ca.crt

    scp /${certs_directory}/${db_node3_address}.node.key root@${db_node3_address}:/data/certs/node.key
    scp /${certs_directory}/${db_node3_address}.node.crt root@${db_node3_address}:/data/certs/node.crt
    scp /${certs_directory}/ca.crt root@${db_node3_address}:/data/certs/ca.crt     

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