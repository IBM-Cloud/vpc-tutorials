#!/bin/sh
set -x
echo onprem.sh

check_vars() {
  all_vars_set=true
  for var in ONPREM_CIDR GW_CLOUD_IP PRESHARED_KEY CLOUD_CIDR DNS_SERVER_IP0 DNS_SERVER_IP1; do 
    echo $var $(eval echo \$$var)
    if [ x = "x$(eval echo \$$var)" ]; then
      echo $var not initialized
      all_vars_set=false
    fi
  done
  if [ $all_vars_set = false ]; then
    exit 1
  fi
}

apt_software(){
  export DEBIAN_FRONTEND=noninteractive
  apt -qq -y update < /dev/null
  apt -qq -y install strongswan postgresql-client curl jq < /dev/null
  apt -qq -y upgrade netplan.io < /dev/null
}

ONPREM_IP_initialize(){
  # Retrieve metadata auth token
  local instance_identity_token
  instance_identity_token=$(curl -X PUT "http://169.254.169.254/instance_identity/v1/token?version=2022-03-08" -H "Metadata-Flavor: ibm" -d '{ "expires_in": 3600 }' | jq -r .access_token)

  # Retrieve floating IP
  ONPREM_IP=$(curl -X GET "http://169.254.169.254/metadata/v1/instance/network_interfaces?version=2022-05-24" -H "Authorization: Bearer $instance_identity_token" | jq -r .network_interfaces[0].floating_ips[0].address)

}
# Configure the strongswan VPN to talk to the vpc/VPN
# The network_config.sh file has the LEFT_IP, LEFT_CIDR, RIGHT_IP, RIGHT_CIDR and PRESHARED_KEY
# I am running on the LEFT computer

strongswan() {
  # see https://blog.ruanbekker.com/blog/2018/02/11/setup-a-site-to-site-ipsec-vpn-with-strongswan-and-preshared-key-authentication/
  echo /etc/sysctl
  cat >> /etc/sysctl.conf << EOF
net.ipv4.ip_forward = 1
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.all.send_redirects = 0
EOF

  # "on-prem" is the source, "cloud" the target
  cat > /etc/ipsec.secrets << EOF
# source destination
$ONPREM_IP $GW_CLOUD_IP : PSK "$PRESHARED_KEY"
EOF

  cat > /etc/ipsec.conf << EOF
# basic configuration
config setup
	charondebug="all"
	uniqueids=yes
	strictcrlpolicy=no

# connection to vpc/vpn datacenter
# left=onprem / right=cloud vpc
conn tutorial-site2site-onprem-to-cloud
  authby=secret
  left=%defaultroute
  leftid=$ONPREM_IP
  leftsubnet=$ONPREM_CIDR
  right=$GW_CLOUD_IP
  rightsubnet=$CLOUD_CIDR
  ike=aes256-sha2_256-modp2048!
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
}

#edit the /etc/nplan/50-cloud-init.yaml file.  The result will be something like this
#where the 10.1.0.5 and 10.1.1.5 are the DNS IP addrsses of the private dns location in the cloud
#network:
#  ethernets:
#    ens3:
#      dhcp4: true
#      match:
#        macaddress: 02:00:0e:3e:fa:c3
#      nameservers:
#        addresses:
#        - 10.1.0.5
#        - 10.1.1.11
#      dhcp4-overrides:
#        use-dns: false
#      set-name: ens3
#  version: 2
dns() {
  cd /etc/netplan
  netplan_file=50-cloud-init.yaml
  python_script=$(cat <<__EOF
import yaml
f = open("$netplan_file")
y = yaml.safe_load(f)
y['network']['ethernets']['ens3']['nameservers'] = {'addresses': ["$DNS_SERVER_IP0", "$DNS_SERVER_IP1"]}
y['network']['ethernets']['ens3']['dhcp4-overrides'] = {'use-dns': False}
print(yaml.dump(y, default_flow_style=False))
__EOF
)
  python3 -c "$python_script" > $netplan_file.new
  mv $netplan_file $netplan_file.bu
  mv $netplan_file.new $netplan_file
  netplan apply
  systemd-resolve --flush-caches
}
dns2() {
  cat >> /etc/systemd/resolved.conf <<__EOF
DNS=$DNS_SERVER_IP0 $DNS_SERVER_IP1
__EOF
  systemctl restart systemd-resolved
  systemd-resolve --flush-caches
}

main() {
  echo onprem.sh main called
  check_vars
  apt_software
  ONPREM_IP_initialize
  strongswan
  dns
  dns2
}

# -- variables will be concatinated here and then a call to main
