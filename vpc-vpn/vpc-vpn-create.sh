#!/bin/bash
set -ex

# Script to set up a VPN connection into a VPC
#
# (C) 2019 IBM
#
# Written by Henrik Loeser, hloeser@de.ibm.com

# include configuration
. $(dirname "$0")/config.sh

# include common functions
. $(dirname "$0")/../scripts/common.sh

# include data generated from the vpc-vpn-create-baseline.sh
. $(dirname "$0")/data.sh

# I am the right hand side
# the strongswan vsi is the left hand side

vpcname="$BASENAME"
fullsubnetname=$SUB_RIGHT_NAME


SUBNET=$(ibmcloud is subnets --json)
SUBNET_ID=$(echo "$SUBNET" | jq -r '.[] | select (.vpc.name=="'${vpcname}'" and .name=="'${fullsubnetname}'") | .id ')

VPN_GW=$(ibmcloud is vpn-gateway-create $BASENAME-gateway $SUBNET_ID --resource-group-name $RESOURCE_GROUP_NAME --json)
VPN_GW_ID=$(echo $VPN_GW | jq -r '.id')

vpcResourceAvailable vpn-gateways $BASENAME-gateway
VPN_GW_IP=$(echo $VPN_GW | jq -r '.id')

#IKE_ID=$(ibmcloud is ike-policy-create $BASENAME-ike-policy sha1 2 aes256 1 --key-lifetime 86400 --json | jq -r '.id')
#IPSEC_ID=$(ibmcloud is ipsec-policy-create $BASENAME-ipsec-policy sha1 aes256 disabled --key-lifetime 3600 --json | jq -r '.id')
ibmcloud is vpn-gateway-connection-create $BASENAME-gateway-conn $VPN_GW_ID $LEFT_IP $PRESHARED_KEY -admin-state-up true
  --local-cidrs $RIGHT_CIDR --peer-cidrs $LEFT_CIDR
#    --ike-policy $IKE_ID --ipsec-policy $IPSEC_ID

echo RIGHT_IP=$VPN_GW_IP >> data.sh
cat data.sh
echo ---------------
echo above is data.sh.  Just added the following line:
echo RIGHT_IP=$VPN_GW_IP

