#!/bin/bash
set -ex

# Script to set up a VPN connection into a VPC
#
# (C) 2019 IBM
#
# Written by Henrik Loeser, hloeser@de.ibm.com

# include configuration
if [ -z "$CONFIG_FILE" ]; then
    echo "using config.sh for configuration"
    . $(dirname "$0")/config.sh
else    
    if [ "$CONFIG_FILE" = "none" ]; then
        echo "won't read any configuration file"
    else
        echo "using $CONFIG_FILE for configuration"
        . $(dirname "$0")/${CONFIG_FILE}
    fi
fi


# include common functions
. $(dirname "$0")/../scripts/common.sh

# include data generated from the vpc-vpn-create-baseline.sh
. $(dirname "$0")/network_config.sh

# I am the right hand side (cloud)
# the strongSwan VSI is the left hand side (onprem)

if [ -z "$REUSE_VPC" ]; then
vpcname="$BASENAME"
else
    vpcname="$REUSE_VPC"
fi
fullsubnetname=$SUB_CLOUD_NAME


SUBNET=$(ibmcloud is subnets --json)
SUBNET_ID=$(echo "$SUBNET" | jq -r '.[] | select (.vpc.name=="'${vpcname}'" and .name=="'${fullsubnetname}'") | .id ')
ibmcloud is vpn-gateway-create $BASENAME-gateway $SUBNET_ID --resource-group-name $RESOURCE_GROUP_NAME
vpcResourceAvailable vpn-gateways $BASENAME-gateway

VPN_GW=$(ibmcloud is vpn-gateways --json | jq '.[]|select(.name=="'$BASENAME-gateway'")')
VPN_GW_ID=$(echo $VPN_GW | jq -r '.id')
VPN_GW_IP=$(echo $VPN_GW | jq -r '.public_ip.address')

#IKE_ID=$(ibmcloud is ike-policy-create $BASENAME-ike-policy sha1 2 aes256 1 --key-lifetime 86400 --json | jq -r '.id')
#IPSEC_ID=$(ibmcloud is ipsec-policy-create $BASENAME-ipsec-policy sha1 aes256 disabled --key-lifetime 3600 --json | jq -r '.id')
ibmcloud is vpn-gateway-connection-create $BASENAME-gateway-conn $VPN_GW_ID $ONPREM_IP $PRESHARED_KEY --admin-state-up true \
   --local-cidr $CLOUD_CIDR --peer-cidr $ONPREM_CIDR
#    --ike-policy $IKE_ID --ipsec-policy $IPSEC_ID

echo GW_CLOUD_IP=$VPN_GW_IP >> $(dirname "$0")/network_config.sh
cat $(dirname "$0")/network_config.sh
echo ---------------
echo above is network_config.sh.  Just added the following line:
echo GW_CLOUD_IP=$VPN_GW_IP

