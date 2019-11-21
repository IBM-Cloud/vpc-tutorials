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

function installNTP {

    log_info "Running apt-get update."
    apt-get update
    [ $? -ne 0 ] && log_error "apt-get update command execution error." && return 1

    log_info "Running apt-get install ntp."
    apt-get install ntp -y
    [ $? -ne 0 ] && log_error "apt-get install command execution error." && return 1

    log_info "Stopping ntp service."
    service ntp stop

    log_info "Modifying /etc/ntp.conf."

    cp /etc/ntp.conf /etc/ntp.conf.orig

    sed -i '/pool /s/^/#/g' /etc/ntp.conf
    sed -i '/server /s/^/#/g' /etc/ntp.conf

cat >> /etc/ntp.conf <<- EOF
server time.adn.networklayer.com iburst
EOF

    log_info "Starting ntp service."
    service ntp start

    return 0
}

function installCockroachDB {
    if [ ! -f "/usr/local/bin/${app_binary}" ]; then

        log_info "wget --output-document=${app_binary_archive} ${app_url}/${app_binary_archive}."
        wget --output-document=${app_binary_archive} ${app_url}/${app_binary_archive}
        [ $? -ne 0 ] && log_error "File not found" && exit 1

        tar xvf ${app_binary_archive}
        cp ${app_directory}/${app_binary} /usr/local/bin
        rm -rf ${app_directory}

        log_info "mkdir /var/lib/cockroach."
        mkdir /var/lib/cockroach

        log_info "useradd ${app_user}."
        useradd ${app_user}

        log_info "chown ${app_user} /var/lib/cockroach."
        chown ${app_user} /var/lib/cockroach
    fi
    return 0
}

function createCerts {
  log_info "Started createCerts."

  if [ ! -f "${ca_directory}/ca.key" ]; then

    mkdir /${certs_directory}

    mkdir /${ca_directory}

    cockroach cert create-ca --certs-dir=/${certs_directory} --ca-key=/${ca_directory}/ca.key

    cockroach cert create-node ${node1_address} localhost 127.0.0.1 ${lb_hostname} --certs-dir=/${certs_directory} --ca-key=/${ca_directory}/ca.key
    mv /${certs_directory}/node.crt /${certs_directory}/${node1_address}.node.crt
    mv /${certs_directory}/node.key /${certs_directory}/${node1_address}.node.key

    cockroach cert create-node ${node2_address} localhost 127.0.0.1 ${lb_hostname} --certs-dir=/${certs_directory} --ca-key=/${ca_directory}/ca.key
    mv /${certs_directory}/node.crt /${certs_directory}/${node2_address}.node.crt
    mv /${certs_directory}/node.key /${certs_directory}/${node2_address}.node.key

    cockroach cert create-node ${node3_address} localhost 127.0.0.1 ${lb_hostname} --certs-dir=/${certs_directory} --ca-key=/${ca_directory}/ca.key
    mv /${certs_directory}/node.crt /${certs_directory}/${node3_address}.node.crt
    mv /${certs_directory}/node.key /${certs_directory}/${node3_address}.node.key

    cockroach cert create-client root --certs-dir=/${certs_directory} --ca-key=/${ca_directory}/ca.key
    cockroach cert create-client maxroach --certs-dir=/${certs_directory} --ca-key=/${ca_directory}/ca.key
  fi
  return 0

}

function first_boot_setup {
    log_info "Started $name server configuration from cloud-init."

    installNTP
    [ $? -ne 0 ] && log_error "Failed NTP installation, review log file $log_file." && return 1
    
    installCockroachDB
    [ $? -ne 0 ] && log_error "Failed cockroach installation, review log file $log_file." && return 1

    sleep 10
    createCerts
    [ $? -ne 0 ] && log_error "Failed createCerts, review log file $log_file." && return 1
    
    return 0
}

first_boot_setup
[ $? -ne 0 ] && log_error "admin server setup had errors." && exit 1

exit 0