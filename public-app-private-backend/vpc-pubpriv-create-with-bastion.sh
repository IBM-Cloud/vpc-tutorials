#!/bin/bash

# Script to deploy VPC resources for an IBM Cloud solution tutorial
#
# (C) 2019 IBM
#
# Written by Henrik Loeser, hloeser@de.ibm.com

# include common functions
. $(dirname "$0")/../scripts/common.sh

if [ -z "$2" ]; then 
              echo usage: $0 zone ssh-keyname [naming-prefix] [resource-group]
              exit
fi

export zone=$1
export keyname=$2

if [ -z "$3" ]; then 
    export prefix=""
else
    export prefix=$3
fi    

if [ -z "$4" ]; then 
    export resourceGroup=$(currentResourceGroup)
else
    export resourceGroup=$4
fi    


export basename="vpc-pubpriv"
export UbuntuImage=$(ibmcloud is images --json | jq -r '.[] | select (.name=="ubuntu-18.04-amd64") | .id')
export SSHKey=$(ibmcloud is keys --json | jq -r '.[] | select (.name=="'$keyname'") | .id')



echo "Creating VPC"
export VPC_OUT=$((ibmcloud is vpc-create ${prefix}${basename} --resource-group-name ${resourceGroup} --json) 2>&1)
if [ $? -ne 0 ]; then
    echo "Error while creating VPC:"
    echo "========================="
    echo "$VPC_OUT"
    exit
fi
export VPCID=$(echo "$VPC_OUT"  | jq -r '.id')


vpcResourceAvailable vpcs ${prefix}${basename}

export PUBGWID=$(ibmcloud is public-gateway-create ${prefix}${basename}-pubgw $VPCID $zone --json | jq -r '.id')
echo "public gateway with id $PUBGWID created"
vpcResourceAvailable public-gateways ${prefix}${basename}-pubgw

export SUB_BACK=$(ibmcloud is subnet-create ${prefix}${basename}-backend-subnet $VPCID $zone --ipv4-address-count 256 --json)
export SUB_BACK_ID=$(echo "$SUB_BACK" | jq -r '.id')


export SUB_FRONT=$(ibmcloud is subnet-create ${prefix}${basename}-frontend-subnet $VPCID $zone  --ipv4-address-count 256 --json)
export SUB_FRONT_ID=$(echo "$SUB_FRONT" | jq -r '.id')

export SUB_BASTION=$(ibmcloud is subnet-create ${prefix}${basename}-bastion-subnet $VPCID $zone  --ipv4-address-count 256 --json)
export SUB_BASTION_ID=$(echo "$SUB_BASTION" | jq -r '.id')


vpcResourceAvailable subnets ${prefix}${basename}-backend-subnet
vpcResourceAvailable subnets ${prefix}${basename}-frontend-subnet
vpcResourceAvailable subnets ${prefix}${basename}-bastion-subnet


export SGBACK=$(ibmcloud is security-group-create ${prefix}${basename}-backend-sg $VPCID --json | jq -r '.id')
export SGFRONT=$(ibmcloud is security-group-create ${prefix}${basename}-frontend-sg $VPCID --json | jq -r '.id')

# Bastion SG
export SGBASTION=$(ibmcloud is security-group-create ${prefix}${basename}-bastion-sg $VPCID --json | jq -r '.id')
# Maintenance / admin SG
export SGMAINT=$(ibmcloud is security-group-create ${prefix}${basename}-maintenance-sg $VPCID --json | jq -r '.id')

vpcResourceAvailable security-groups ${prefix}${basename}-backend-sg
vpcResourceAvailable security-groups ${prefix}${basename}-frontend-sg
vpcResourceAvailable security-groups ${prefix}${basename}-bastion-sg
vpcResourceAvailable security-groups ${prefix}${basename}-maintenance-sg


#ibmcloud is security-group-rule-add GROUP_ID DIRECTION PROTOCOL
echo "Creating rules"
echo "backend"
ibmcloud is security-group-rule-add $SGBACK inbound tcp --remote $SGFRONT --port-min 3300 --port-max 3310 > /dev/null
#ibmcloud is security-group-rule-add $SGBACK outbound tcp --remote "0.0.0.0/0" --port-min 80 --port-max 80 > /dev/null
#ibmcloud is security-group-rule-add $SGBACK outbound tcp --remote "0.0.0.0/0" --port-min 443 --port-max 443 > /dev/null

echo "frontend"
# inbound
ibmcloud is security-group-rule-add $SGFRONT inbound tcp --remote "0.0.0.0/0" --port-min 80 --port-max 80 > /dev/null
ibmcloud is security-group-rule-add $SGFRONT inbound tcp --remote "0.0.0.0/0" --port-min 443 --port-max 443 > /dev/null
ibmcloud is security-group-rule-add $SGBASTION inbound icmp --remote "0.0.0.0/0" --icmp-type 8 > /dev/null
# outbound
ibmcloud is security-group-rule-add $SGFRONT outbound tcp --remote $SGBACK --port-min 3300 --port-max 3310 > /dev/null
#ibmcloud is security-group-rule-add $SGFRONT outbound tcp --remote "0.0.0.0/0" --port-min 80 --port-max 80 > /dev/null
#ibmcloud is security-group-rule-add $SGFRONT outbound tcp --remote "0.0.0.0/0" --port-min 443 --port-max 443 > /dev/null


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


# Frontend and backend server
echo "Creating VSIs"
export BACK_VSI=$(ibmcloud is instance-create ${prefix}${basename}-backend-vsi $VPCID $zone b-2x8 $SUB_BACK_ID 1000 --image-id $UbuntuImage --key-ids $SSHKey --security-group-ids $SGBACK,$SGMAINT --json)
export FRONT_VSI=$(ibmcloud is instance-create ${prefix}${basename}-frontend-vsi $VPCID $zone b-2x8 $SUB_FRONT_ID 1000 --image-id $UbuntuImage --key-ids $SSHKey --security-group-ids $SGFRONT,$SGMAINT --json)
export BASTION_VSI=$(ibmcloud is instance-create ${prefix}${basename}-bastion-vsi $VPCID $zone c-2x4 $SUB_BASTION_ID 1000 --image-id $UbuntuImage --key-ids $SSHKey --security-group-ids $SGBASTION --json)

export FRONT_VSI_NIC_ID=$(echo "$FRONT_VSI" | jq -r '.primary_network_interface.id')
export BASTION_VSI_NIC_ID=$(echo "$BASTION_VSI" | jq -r '.primary_network_interface.id')
export FRONT_NIC_IP=$(echo "$FRONT_VSI" | jq -r '.primary_network_interface.primary_ipv4_address')
export BACK_NIC_IP=$(echo "$BACK_VSI" | jq -r '.primary_network_interface.primary_ipv4_address')

vpcResourceAvailable instances ${prefix}${basename}-frontend-vsi
vpcResourceAvailable instances ${prefix}${basename}-bastion-vsi

# Adding the PGW here because of trouble combining it above
echo "Adding public gateway to subnets"
ibmcloud is subnet-update $SUB_BACK_ID --public-gateway-id $PUBGWID > /dev/null
ibmcloud is subnet-update $SUB_FRONT_ID --public-gateway-id $PUBGWID > /dev/null


# Floating IP for frontend
export FRONT_IP_ADDRESS=$(ibmcloud is floating-ip-reserve ${prefix}${basename}-frontend-ip --nic-id $FRONT_VSI_NIC_ID --json | jq -r '.address')
export BASTION_IP_ADDRESS=$(ibmcloud is floating-ip-reserve ${prefix}${basename}-bastion-ip --nic-id $BASTION_VSI_NIC_ID --json | jq -r '.address')

echo "Your frontend IP address: $FRONT_IP_ADDRESS"
echo "Your bastion IP address: $BASTION_IP_ADDRESS"
echo "Your frontend internal IP address: $FRONT_NIC_IP"
echo "Your backend internal IP address: $BACK_NIC_IP"
echo ""
echo "It may take few minutes for the new routing to become active."
echo "To connect to the frontend: ssh -J root@$BASTION_IP_ADDRESS root@$FRONT_NIC_IP"
echo "To connect to the backend: ssh -J root@$BASTION_IP_ADDRESS root@$BACK_NIC_IP"
echo ""
echo "Install software: ssh -J root@$BASTION_IP_ADDRESS root@$BACK_NIC_I 'bash -s' < install-software.sh"


# ssh -J root@$BASTION_IP_ADDRESS root@$BACK_NIC_I 'bash -s' < install-software.sh