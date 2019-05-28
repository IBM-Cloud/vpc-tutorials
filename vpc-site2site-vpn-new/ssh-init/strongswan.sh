#!/bin/bash
name=strongswan
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

function installStrongswan {

    log_info "${FUNCNAME[0]}: Running apt-get update."
    apt-get -qq update < /dev/null

    log_info "${FUNCNAME[0]}: Running apt-get install strongswan."
    apt-get -qq install strongswan -y < /dev/null

    log_info "${FUNCNAME[0]}: Running cat >> /etc/sysctl.conf."

cat >> /etc/sysctl.conf << EOF
net.ipv4.ip_forward = 1
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.all.send_redirects = 0
EOF

    log_info "${FUNCNAME[0]}: Running cat > /etc/ipsec.secrets."

cat > /etc/ipsec.secrets << EOF
# source destination
$ONPREM_IP $GW_CLOUD_IP : PSK "$PRESHARED_KEY"
EOF

    log_info "${FUNCNAME[0]}: Running cat > /etc/ipsec.conf."

cat > /etc/ipsec.conf << EOF
# basic configuration
config setup
        charondebug="all"
        uniqueids=yes
        strictcrlpolicy=no
# connection to vpc/vpn datacenter 
# left=onprem / right=vpc
conn tutorial-site2site-onprem-to-cloud
  authby=secret
  left=%defaultroute
  leftid=$ONPREM_IP
  leftsubnet=$ONPREM_CIDR
  right=$GW_CLOUD_IP
  rightsubnet=$CLOUD_CIDR
  ike=aes256-sha2_256-modp1024!
  esp=aes256-sha2_256!
  keyingtries=0
  ikelifetime=1h
  lifetime=8h
  dpddelay=30
  dpdtimeout=120
  dpdaction=restart
  auto=start
EOF

    log_info "${FUNCNAME[0]}: Running ipsec restart."

ipsec restart

    return 0
}

function first_boot_setup {
    log_info "${FUNCNAME[0]}: Started ${name} server configuration from cloud-init."

    installStrongswan
    [ $? -ne 0 ] && log_error "${FUNCNAME[0]}: Failed strongswan installation, review log file ${log_file}." && exit 1
}

first_boot_setup