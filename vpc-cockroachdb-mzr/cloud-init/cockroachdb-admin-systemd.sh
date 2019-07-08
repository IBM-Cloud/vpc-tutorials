#!/bin/bash

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

function installNTP {

    log_info "${FUNCNAME[0]}: Running apt-get update."
    apt-get update

    log_info "${FUNCNAME[0]}: Running apt-get install ntp."
    apt-get install ntp -y

    log_info "${FUNCNAME[0]}: Stopping ntp service."
    service ntp stop

    log_info "${FUNCNAME[0]}: Modifying /etc/ntp.conf."

    cp /etc/ntp.conf /etc/ntp.conf.orig

    sed -i '/pool /s/^/#/g' /etc/ntp.conf
    sed -i '/server /s/^/#/g' /etc/ntp.conf

cat >> /etc/ntp.conf <<- EOF
server time.adn.networklayer.com iburst
EOF

    log_info "${FUNCNAME[0]}: Starting ntp service."
    service ntp start

    return 0
}

function installCockroachDB {
    local app_url=https://binaries.cockroachdb.com
    local app_binary_archive=cockroach-v2.1.6.linux-amd64.tgz
    local app_binary=cockroach
    local app_user=cockroach
    local app_directory=cockroach-v2.1.6.linux-amd64

    log_info "${FUNCNAME[0]}: wget --quiet --no-clobber --output-document=${app_binary_archive} ${app_url}/${app_binary_archive}."
    wget --quiet --no-clobber --output-document=${app_binary_archive} ${app_url}/${app_binary_archive}
    [ $? -ne 0 ] && log_error "${FUNCNAME[0]}: File not found" && exit 1

    tar xvf ${app_binary_archive}
    cp ${app_directory}/${app_binary} /usr/local/bin
    rm -rf ${app_directory}

    log_info "${FUNCNAME[0]}: mkdir /var/lib/cockroach."
    mkdir /var/lib/cockroach

    log_info "${FUNCNAME[0]}: useradd ${app_user}."
    useradd ${app_user}

    log_info "${FUNCNAME[0]}: chown ${app_user} /var/lib/cockroach."
    chown ${app_user} /var/lib/cockroach

    return 0
}

function createCerts {
  local certs_directory=/certs
  local ca_directory=/cas

  log_info "${FUNCNAME[0]}: Started createCerts."

  mkdir ${certs_directory}

  mkdir ${ca_directory}

  cockroach cert create-ca --certs-dir=${certs_directory} --ca-key=${ca_directory}/ca.key

  if [ ! -z $node1_address ]; then
    cockroach cert create-node ${node1_address} localhost 127.0.0.1 ${lb1_address} ${lb2_address} ${lb_hostname} --certs-dir=${certs_directory} --ca-key=${ca_directory}/ca.key
    mv ${certs_directory}/node.crt ${certs_directory}/${node1_address}.node.crt
    mv ${certs_directory}/node.key ${certs_directory}/${node1_address}.node.key
  fi

  if [ ! -z $node2_address ]; then
    cockroach cert create-node ${node2_address} localhost 127.0.0.1 ${lb1_address} ${lb2_address} ${lb_hostname} --certs-dir=${certs_directory} --ca-key=${ca_directory}/ca.key
    mv ${certs_directory}/node.crt ${certs_directory}/${node2_address}.node.crt
    mv ${certs_directory}/node.key ${certs_directory}/${node2_address}.node.key
  fi

  if [ ! -z $node3_address ]; then
    cockroach cert create-node ${node3_address} localhost 127.0.0.1 ${lb1_address} ${lb2_address} ${lb_hostname} --certs-dir=${certs_directory} --ca-key=${ca_directory}/ca.key
    mv ${certs_directory}/node.crt ${certs_directory}/${node3_address}.node.crt
    mv ${certs_directory}/node.key ${certs_directory}/${node3_address}.node.key
  fi

  if [ ! -z $node4_address ]; then
    cockroach cert create-node ${node4_address} localhost 127.0.0.1 ${lb1_address} ${lb2_address} ${lb_hostname} --certs-dir=${certs_directory} --ca-key=${ca_directory}/ca.key
    mv ${certs_directory}/node.crt ${certs_directory}/${node4_address}.node.crt
    mv ${certs_directory}/node.key ${certs_directory}/${node4_address}.node.key
  fi

  if [ ! -z $node5_address ]; then
    cockroach cert create-node ${node5_ip} localhost 127.0.0.1 ${lb1_address} ${lb2_address} ${lb_hostname} --certs-dir=${certs_directory} --ca-key=${ca_directory}/ca.key
    mv ${certs_directory}/node.crt ${certs_directory}/${node5_address}.node.crt
    mv ${certs_directory}/node.key ${certs_directory}/${node5_address}.node.key
  fi

  cockroach cert create-client root --certs-dir=${certs_directory} --ca-key=${ca_directory}/ca.key
  cockroach cert create-client maxroach --certs-dir=${certs_directory} --ca-key=${ca_directory}/ca.key
  
  return 0

}

function first_boot_setup {
    log_info "${FUNCNAME[0]}: Started ${name} server configuration from cloud-init."

    installNTP
    [ $? -ne 0 ] && log_error "${FUNCNAME[0]}: Failed NTP installation, review log file ${log_file}." && exit 1
    
    installCockroachDB
    [ $? -ne 0 ] && log_error "${FUNCNAME[0]}: Failed cockroach installation, review log file ${log_file}." && exit 1

    sleep 10
    createCerts
    [ $? -ne 0 ] && log_error "${FUNCNAME[0]}: Failed createCerts, review log file ${log_file}." && exit 1

    return 0
}

first_boot_setup
