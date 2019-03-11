#!/bin/bash

# Configure the strongswan VPN to talk to the vpc/VPN
# The data.sh file has the LEFT_IP, LEFT_CIDR, RIGHT_IP, RIGHT_CIDR and PRESHARED_KEY
# I am running on the LEFT computer

# recording of environment:
set -x
output=/strongswan.data
echo strongswan.bash > $output
pwd >> $output
env >> $output
ls -ld data.sh >> $output
cat data.sh >> $output
source data.sh

sleep 120
apt-get -qq update < /dev/null
# apt upgrade -y < /dev/null
apt-get -qq install strongswan -y < /dev/null

# see https://blog.ruanbekker.com/blog/2018/02/11/setup-a-site-to-site-ipsec-vpn-with-strongswan-and-preshared-key-authentication/
cat >> /etc/sysctl.conf << EOF
net.ipv4.ip_forward = 1
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.all.send_redirects = 0
EOF

# assuming I am left
cat > /etc/ipsec.secrets << EOF
# source destination
$LEFT_IP $RIGHT_IP : PSK "$PRESHARED_KEY"
EOF

cat > /etc/ipsec.conf << EOF
# basic configuration
config setup
        charondebug="all"
        uniqueids=yes
        strictcrlpolicy=no

# connection to vpc/vpn datacenter
conn paris-me-left-to-amsterdam-vpc
  authby=secret
  left=%defaultroute
  leftid=$LEFT_IP
  leftsubnet=$LEFT_CIDR
  right=$RIGHT_IP
  rightsubnet=$RIGHT_CIDR
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


ipsec restart
ipsec status
