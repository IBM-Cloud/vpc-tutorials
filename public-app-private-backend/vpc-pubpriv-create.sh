#!/bin/bash

if [ -z "$2" ]; then 
              echo usage: $0 zone ssh-keyname [naming-prefix]
              exit
fi

export zone=$1
export keyname=$2

if [ -z "$3" ]; then 
    export prefix=""
else
    export prefix=$3
fi    

export basename="vpc-pubpriv"
export UbuntuImage=$(ibmcloud is images --json | jq -r '.[] | select (.name=="ubuntu-16.04-amd64") | .id')
export SSHKey=$(ibmcloud is keys --json | jq -r '.[] | select (.name=="'$keyname'") | .id')

function vpcResourceAvailable {
    until ibmcloud is $1 --json | jq -c '.[] | select (.name=="'$2'" and .status=="available") | [.status,.name]' > /dev/null
    do
        sleep 10
    done        
    echo "$2 became available"
}


echo "Creating VPC"
export VPCID=$(ibmcloud is vpc-create ${prefix}${basename} --resource-group-name hloeser@de.ibm.com --json | jq -r '.id')

vpcResourceAvailable vpcs ${prefix}${basename}

export PUBGWID=$(ibmcloud is pubgwc ${prefix}${basename}-pubgw $VPCID $zone --json | jq -r '.id')
echo "public gateway with id $PUBGWID created"

export SUB_BACK=$(ibmcloud is subnet-create ${prefix}${basename}-backend-subnet $VPCID $zone --public-gateway-id $PUBGWID --ipv4-address-count 256 --json)
export SUB_BACK_ID=$(echo "$SUB_BACK" | jq -r '.id')
echo "Success"


export SUB_FRONT=$(ibmcloud is subnet-create ${prefix}${basename}-frontend-subnet $VPCID $zone --public-gateway-id $PUBGWID --ipv4-address-count 256 --json)
export SUB_FRONT_ID=$(echo "$SUB_FRONT" | jq -r '.id')
echo "Success"



vpcResourceAvailable subnets ${prefix}${basename}-backend-subnet
vpcResourceAvailable subnets ${prefix}${basename}-frontend-subnet


export SGBACK=$(ibmcloud is security-group-create ${prefix}${basename}-backend-sg $VPCID --json | jq -r '.id')
export SGFRONT=$(ibmcloud is security-group-create ${prefix}${basename}-frontend-sg $VPCID --json | jq -r '.id')

vpcResourceAvailable security-groups ${prefix}${basename}-backend-sg
vpcResourceAvailable security-groups ${prefix}${basename}-frontend-sg

#ibmcloud is security-group-rule-add GROUP_ID DIRECTION PROTOCOL
echo "Creating rules"
ibmcloud is security-group-rule-add $SGBACK inbound tcp --remote $SGFRONT --port-min 3300 --port-max 3310 > /dev/null
ibmcloud is security-group-rule-add $SGBACK outbound tcp --remote "0.0.0.0/0" --port-min 80 --port-max 80 > /dev/null
ibmcloud is security-group-rule-add $SGBACK outbound tcp --remote "0.0.0.0/0" --port-min 443 --port-max 443 > /dev/null

ibmcloud is security-group-rule-add $SGFRONT inbound tcp --remote "0.0.0.0/0" --port-min 80 --port-max 80 > /dev/null
ibmcloud is security-group-rule-add $SGFRONT inbound tcp --remote "0.0.0.0/0" --port-min 443 --port-max 443 > /dev/null
ibmcloud is security-group-rule-add $SGFRONT inbound tcp --remote "0.0.0.0/0" --port-min 22 --port-max 22 > /dev/null
ibmcloud is security-group-rule-add $SGFRONT outbound tcp --remote $SGBACK --port-min 3300 --port-max 3310 > /dev/null
ibmcloud is security-group-rule-add $SGFRONT outbound tcp --remote "0.0.0.0/0" --port-min 80 --port-max 80 > /dev/null
ibmcloud is security-group-rule-add $SGFRONT outbound tcp --remote "0.0.0.0/0" --port-min 443 --port-max 443 > /dev/null


# Frontend and backend server
echo "Creating VSIs"
export BACK_VSI=$(ibmcloud is instance-create ${prefix}${basename}-backend-vsi $VPCID $zone b-2x8 $SUB_BACK_ID 1000 --image-id $UbuntuImage --key-ids $SSHKey --security-group-ids $SGBACK --json)
export FRONT_VSI=$(ibmcloud is instance-create ${prefix}${basename}-frontend-vsi $VPCID $zone b-2x8 $SUB_FRONT_ID 1000 --image-id $UbuntuImage --key-ids $SSHKey --security-group-ids $SGFRONT  --json)
export FRONT_VSI_NIC_ID=$(echo "$FRONT_VSI" | jq -r '.primary_network_interface.id')

vpcResourceAvailable instances ${prefix}${basename}-frontend-vsi
# Floating IP for frontend
export FRONT_IP_ADDRESS=$(ibmcloud is floating-ip-reserve ${prefix}${basename}-frontend-ip --nic-id $FRONT_VSI_NIC_ID | jq -r '.address')

echo "Your frontend IP address: $FRONT_IP_ADDRESS"