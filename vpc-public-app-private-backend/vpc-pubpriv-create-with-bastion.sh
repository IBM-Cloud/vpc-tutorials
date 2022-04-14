#!/bin/bash

# Script to deploy VPC resources for an IBM Cloud solution tutorial
#
# (C) 2019 IBM
#
# Written by Henrik Loeser, hloeser@de.ibm.com

# usage: $0 region ssh-key-name prefix-string [ naming-prefix [ resource-output-file [ user-data-file [ image-name ] ] ] ]
# usage: $0 us-south-1 pfq testx default resources.sh cloud-config.yaml ibm-centos-7-6-minimal-amd64-2

# Exit on errors
set -e
set -o pipefail

# avoid invalid characters in ibmcloud output
export IBMCLOUD_COLOR=false

# include common functions
. $(dirname "$0")/../scripts/common.sh

if [ -z "$2" ]; then 
              echo "usage: [REUSE_VPC=vpcname] $0 region ssh-key-name prefix-string [ naming-prefix [ resource-output-file [ user-data-file [ image-name ]]]]"
              exit
fi

export zone=$1
export KEYNAME=$2

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

if [ ! -z "$5" ]; then 
    resource_file=$5
fi

if [ ! -z "$6" ]; then 
    user_data_frontend=$6
else
    user_data_frontend='#!/bin/bash
apt-get update
apt-get install -y nginx
echo "I am the frontend server" > /var/www/html/index.html
service nginx start
'
fi

if [ ! -z "$7" ]; then 
    user_data_backend=$6
else
    user_data_backend='#!/bin/bash
apt-get update
apt-get install -y nginx
echo "I am the backend server" > /var/www/html/index.html
service nginx start
'
fi

if [ -z "$8" ]; then 
    image=$(ubuntu1804)
else
    image=$8
fi

export basename="vpc-pubpriv"
export ImageId=$(ibmcloud is images --output json | jq -r '.[] | select (.name=="'$image'") | .id')
export SSHKey=$(SSHKeynames2UUIDs $KEYNAME)

export BASENAME="${prefix}${basename}"

# check if to reuse existing VPC
if [ -z "$REUSE_VPC" ]; then
    echo "Creating VPC"
    VPC_OUT=$(ibmcloud is vpc-create ${BASENAME} --resource-group-name ${resourceGroup} --output json)
    if [ $? -ne 0 ]; then
        echo "Error while creating VPC:"
        echo "========================="
        echo "$VPC_OUT"
        exit
    fi
    VPCID=$(echo "$VPC_OUT"  | jq -r '.id')
    vpcResourceAvailable vpcs $BASENAME
    VPCNAME=$BASENAME
else
    echo "Reusing VPC $REUSE_VPC"
    VPC_OUT=$(ibmcloud is vpcs --output json)
    VPCID=$(echo "${VPC_OUT}" | jq -r '.[] | select (.name=="'${REUSE_VPC}'") | .id')
    echo "$VPCID"
    VPCNAME=$REUSE_VPC
fi


# Create a bastion
#
# set up few variables
BASTION_SSHKEY=$SSHKey
BASTION_IMAGE=$ImageId
BASTION_ZONE=$zone
# include file to create the bastion resources
. $(dirname "$0")/../scripts/bastion-create.sh


# Create Public Gateways if not available
vpcCreatePublicGateways $VPCNAME

# Identify the right public gateway to allow software installation on backend VSI
PUBGWID=$( vpcPublicGatewayIDbyZone $VPCNAME $zone )
echo "PUBGWID: ${PUBGWID}"


if ! SUB_BACK=$(ibmcloud is subnet-create ${BASENAME}-backend-subnet $VPCID $zone --ipv4-address-count 256 --public-gateway-id $PUBGWID --output json)
then
    code=$?
    echo ">>> ibmcloud is subnet-create ${BASENAME}-backend-subnet $VPCID $zone --ipv4-address-count 256 --public-gateway-id $PUBGWID --output json"
    echo "${SUB_BACK}"
    exit $code
fi
SUB_BACK_ID=$(echo "$SUB_BACK" | jq -r '.id')


if ! SUB_FRONT=$(ibmcloud is subnet-create ${BASENAME}-frontend-subnet $VPCID $zone  --ipv4-address-count 256 --output json)
then
    code=$?
    echo ">>> ibmcloud is subnet-create ${BASENAME}-frontend-subnet $VPCID $zone  --ipv4-address-count 256 --output json"
    echo "${SUB_FRONT}"
    exit $code
fi
SUB_FRONT_ID=$(echo "$SUB_FRONT" | jq -r '.id')

vpcResourceAvailable subnets ${BASENAME}-backend-subnet
vpcResourceAvailable subnets ${BASENAME}-frontend-subnet

if ! SGBACK_JSON=$(ibmcloud is security-group-create ${BASENAME}-backend-sg $VPCID --output json)
then
    code=$?
    echo ">>> ibmcloud is security-group-create ${BASENAME}-backend-sg $VPCID --output json"
    echo "${SGBACK_JSON}"
    exit $code
fi
SGBACK=$(echo "${SGBACK_JSON}" | jq -r '.id')

if ! SGFRONT_JSON=$(ibmcloud is security-group-create ${BASENAME}-frontend-sg $VPCID --output json)
then
    code=$?
    echo ">>> ibmcloud is security-group-create ${BASENAME}-frontend-sg $VPCID --output json"
    echo "${SGFRONT_JSON}"
    exit $code
fi
SGFRONT=$(echo "${SGFRONT_JSON}" | jq -r '.id')

# Example has the frontend responding to port 80 from anywhere.  The backend responds from 80 but only from the frontend
#ibmcloud is security-group-rule-add GROUP_ID DIRECTION PROTOCOL
echo "Creating rules"
echo "backend"
ibmcloud is security-group-rule-add $SGBACK inbound tcp --remote $SGFRONT --port-min 80 --port-max 80 > /dev/null

echo "frontend"
# inbound
ibmcloud is security-group-rule-add $SGFRONT inbound tcp --remote "0.0.0.0/0" --port-min 80 --port-max 80 > /dev/null
# outbound
ibmcloud is security-group-rule-add $SGFRONT outbound tcp --remote $SGBACK --port-min 80 --port-max 80 > /dev/null


# Frontend and backend server
echo "Creating VSIs"
instance_create="ibmcloud is instance-create ${BASENAME}-backend-vsi $VPCID $zone $(instance_profile) $SUB_BACK_ID --image-id $ImageId --key-ids $SSHKey --security-group-ids $SGBACK,$SGMAINT --output json"
if ! BACK_VSI=$($instance_create --user-data "$user_data_backend")
then
    code=$?
    echo ">>> $instance_create --user-data $user_data_backend"
    echo "${BACK_VSI}"
    exit $code
fi

instance_create="ibmcloud is instance-create ${BASENAME}-frontend-vsi $VPCID $zone $(instance_profile) $SUB_FRONT_ID --image-id $ImageId --key-ids $SSHKey --security-group-ids $SGFRONT,$SGMAINT --output json"
if ! FRONT_VSI=$($instance_create --user-data "$user_data_frontend")
then
    code=$?
    echo ">>> $instance_create --user-data $user_data_frontend"
    echo "${FRONT_VSI}"
    exit $code
fi

vpcResourceRunning instances ${BASENAME}-frontend-vsi
vpcResourceRunning instances ${BASENAME}-bastion-vsi

# network interface is not initially returned
instanceId=$(echo "$BACK_VSI" | jq -r '.id')
BACK_VSI=$(ibmcloud is instance $instanceId --output json)
instanceId=$(echo "$FRONT_VSI" | jq -r '.id')
FRONT_VSI=$(ibmcloud is instance $instanceId --output json)

export FRONT_VSI_NIC_ID=$(echo "$FRONT_VSI" | jq -r '.primary_network_interface.id')
export FRONT_NIC_IP=$(echo "$FRONT_VSI" | jq -r '.primary_network_interface.primary_ip.address')
export BACK_VSI_NIC_ID=$(echo "$BACK_VSI" | jq -r '.primary_network_interface.id')
export BACK_NIC_IP=$(echo "$BACK_VSI" | jq -r '.primary_network_interface.primary_ip.address')

# Floating IP for frontend
if ! FRONT_IP_JSON=$(ibmcloud is floating-ip-reserve ${BASENAME}-frontend-ip --nic-id $FRONT_VSI_NIC_ID --output json)
then
    code=$?
    echo ">>> ibmcloud is floating-ip-reserve ${BASENAME}-frontend-ip --nic-id $FRONT_VSI_NIC_ID --output json"
    echo "${FRONT_IP_JSON}"
    exit $code
fi
FRONT_IP_ADDRESS=$(echo "${FRONT_IP_JSON}" | jq -r '.address')

vpcResourceAvailable floating-ips ${BASENAME}-frontend-ip

echo "Your frontend IP address: $FRONT_IP_ADDRESS"
echo "Your bastion IP address: $BASTION_IP_ADDRESS"
echo "Your frontend internal IP address: $FRONT_NIC_IP"
echo "Your backend internal IP address: $BACK_NIC_IP"
echo ""
echo "It may take few minutes for the new routing to become active."
echo "To connect to the frontend: ssh -J root@$BASTION_IP_ADDRESS root@$FRONT_NIC_IP"
echo "To connect to the backend: ssh -J root@$BASTION_IP_ADDRESS root@$BACK_NIC_IP"
echo ""
echo "Install software: ssh -J root@$BASTION_IP_ADDRESS root@$BACK_NIC_IP 'bash -s' < install-software.sh"
echo ""
echo "Turn maintenance off and on by removing the security group from the frontend or backend subnet, frontend example:"
echo $(dirname "$0")/vpc-maintenance.sh frontend off $prefix $REUSE_VPC
echo $(dirname "$0")/vpc-maintenance.sh frontend on $prefix $REUSE_VPC

if [ ! -z "$resource_file" ]; then
    cat > $resource_file <<EOF
FRONT_IP_ADDRESS=$FRONT_IP_ADDRESS
BASTION_IP_ADDRESS=$BASTION_IP_ADDRESS
FRONT_NIC_IP=$FRONT_NIC_IP
BACK_NIC_IP=$BACK_NIC_IP
FRONT_VSI_NIC_ID=$FRONT_VSI_NIC_ID
BACK_VSI_NIC_ID=$BACK_VSI_NIC_ID
EOF
fi


# ssh -J root@$BASTION_IP_ADDRESS root@$BACK_NIC_I 'bash -s' < install-software.sh

