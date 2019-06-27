#!/bin/bash
#set -ex

# Script to deploy VPC resources for an IBM Cloud solution tutorial
#
# (C) 2019 IBM
#
# Written by Henrik Loeser, hloeser@de.ibm.com

# Exit on errors
set -e
set -o pipefail

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

echo "Going to create VSI with name ${BASENAME}-onprem-vsi in domain solution-tutorial.cloud.ibm"
ONPREM_VSI=$(ibmcloud sl vs create -H ${BASENAME}-onprem-vsi -D solution-tutorial.cloud.ibm -c 1 -m 1024 -o Ubuntu_latest -d ${DATACENTER_ONPREM} -k ${SSHKEYNAME_CLASSIC} --force)

ONPREM_VSI_ID=$(echo "${ONPREM_VSI}" | grep ID | awk {'print $2'})

echo "New machine has ID ${ONPREM_VSI_ID}, now waiting for it to become available."

until ibmcloud sl call-api SoftLayer_Virtual_Guest getPowerState --init ${ONPREM_VSI_ID} | jq -c --exit-status 'select (.keyName=="RUNNING" and .name=="Running")' >/dev/null
do 
    echo -n "."
    sleep 10
done
echo ""

# Obtain the IP address (primary IP address)
VSI_ONPREM_IP=$(ibmcloud sl call-api SoftLayer_Virtual_Guest getObject --init ${ONPREM_VSI_ID} | jq -r '.primaryIpAddress')
# Compose the onprem CIDR out of the base network ID and the CIDR
ONPREM_CIDR=$(ibmcloud sl call-api SoftLayer_Virtual_Guest getNetworkVlans --init ${ONPREM_VSI_ID} --mask subnets | jq -r '.[] | select (.subnets[0].addressSpace=="PRIVATE") |  .subnets[] | [.networkIdentifier,"/", .cidr|tostring] |  add')

echo "ONPREM_CIDR=${ONPREM_CIDR}"
echo "VSI_ONPREM_IP=${VSI_ONPREM_IP}"

# Concatenate the info to the network configuration file
cat >> $(dirname "$0")/network_config.sh << EOF
VSI_ONPREM_IP=${VSI_ONPREM_IP}
ONPREM_CIDR=${ONPREM_CIDR}
# Connect from your machine to the onprem VSI
# ssh root@$VSI_ONPREM_IP
EOF