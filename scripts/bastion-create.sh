#!/bin/bash

# Script to add a bastion and related resources to an existing VPC environment
# It adds:
# - a subnet
# - a bastion and a maintenance security group with rules
# - a VSI for the bastion
# - a floating IP
#
# It needs the following environment variables set
# - VPCID
# - BASENAME
# - BASTION_SSHKEY
# - BASTION_IMAGE (optional, default Ubuntu)
# - BASTION_NAME (optional, default "bastion")
# - BASTION_ZONE
#
# (C) 2019 IBM
#
# Written by Henrik Loeser, hloeser@de.ibm.com


# include common functions
. $(dirname "$0")/../scripts/common.sh

# Some checks before getting started...
#
# check that we know the VPC id
if [ -z "$VPCID" ]; then
    echo "VPCID required"
    exit
fi

# check that IDs for SSH keys have been provided
if [ -z "$BASTION_SSHKEY" ]; then
    echo "SSH key required (BASTION_SSHKEY)"
    exit
fi

# we need to have the zone to provision to
if [ -z "$BASTION_ZONE" ]; then
    echo "zone required (BASTION_ZONE)"
    exit
fi

# check for the basename
if [ -z "$BASENAME" ]; then
    echo "basename required"
    exit
fi

# check for the optional image ID
if [ -z "$BASTION_IMAGE" ]; then
    echo "no image specified, using Ubuntu"
    BASTION_IMAGE=$(ibmcloud is images --json | jq -r '.[] | select (.name=="ubuntu-18.04-amd64") | .id')
fi

# check for the optional bastion name    
if [ -z "$BASTION_NAME" ]; then
    echo "no bastion name specified, using 'bastion'"
    BASTION_NAME="bastion"
fi




SUB_BASTION=$(ibmcloud is subnet-create ${BASENAME}-${BASTION_NAME}-subnet $VPCID $BASTION_ZONE  --ipv4-address-count 256 --json)
SUB_BASTION_ID=$(echo "$SUB_BASTION" | jq -r '.id')

vpcResourceAvailable subnets ${BASENAME}-${BASTION_NAME}-subnet

# Bastion SG
export SGBASTION=$(ibmcloud is security-group-create ${BASENAME}-${BASTION_NAME}-sg $VPCID --json | jq -r '.id')
# Maintenance / admin SG
export SGMAINT=$(ibmcloud is security-group-create ${BASENAME}-maintenance-sg $VPCID --json | jq -r '.id')

sleep 20


#ibmcloud is security-group-rule-add GROUP_ID DIRECTION PROTOCOL
echo "Creating rules"

echo "bastion"
# inbound
ibmcloud is security-group-rule-add $SGBASTION inbound tcp --remote "0.0.0.0/0" --port-min 22 --port-max 22 > /dev/null
ibmcloud is security-group-rule-add $SGBASTION inbound icmp --remote "0.0.0.0/0" --icmp-type 8 > /dev/null
# outbound
ibmcloud is security-group-rule-add $SGBASTION outbound tcp --remote $SGMAINT --port-min 22 --port-max 22 > /dev/null

echo "maintenance"
# inbound
ibmcloud is security-group-rule-add $SGMAINT inbound tcp --remote $SGBASTION --port-min 22 --port-max 22 > /dev/null
# outbound
ibmcloud is security-group-rule-add $SGMAINT outbound tcp --remote "0.0.0.0/0" --port-min 443 --port-max 443 > /dev/null
ibmcloud is security-group-rule-add $SGMAINT outbound tcp --remote "0.0.0.0/0" --port-min 80 --port-max 80 > /dev/null
ibmcloud is security-group-rule-add $SGMAINT outbound tcp --remote "0.0.0.0/0" --port-min 53 --port-max 53 > /dev/null
ibmcloud is security-group-rule-add $SGMAINT outbound udp --remote "0.0.0.0/0" --port-min 53 --port-max 53 > /dev/null


# Bastion server
echo "Creating bastion VSI"
export BASTION_VSI=$(ibmcloud is instance-create ${BASENAME}-${BASTION_NAME}-vsi $VPCID $BASTION_ZONE c-2x4 $SUB_BASTION_ID 1000 --image-id $BASTION_IMAGE --key-ids $BASTION_SSHKEY --security-group-ids $SGBASTION --json)
export BASTION_VSI_NIC_ID=$(echo "$BASTION_VSI" | jq -r '.primary_network_interface.id')

vpcResourceRunning instances ${BASENAME}-${BASTION_NAME}-vsi


# Floating IP for bastion
export BASTION_IP_ADDRESS=$(ibmcloud is floating-ip-reserve ${BASENAME}-${BASTION_NAME}-ip --nic-id $BASTION_VSI_NIC_ID --json | jq -r '.address')


echo "Your bastion IP address: $BASTION_IP_ADDRESS"
echo ""

