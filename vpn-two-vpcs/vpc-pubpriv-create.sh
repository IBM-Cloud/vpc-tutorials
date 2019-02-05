#!/bin/bash

if [ -z "$3" ]; then 
              echo usage: $0 zone ssh-keyname cidr-block [naming-prefix]
              exit
fi

export zone=$1
export keyname=$2
export cidrBlock=$3

if [ -z "$4" ]; then 
    export prefix=""
else
    export prefix=$4
fi    

export basename="vpn"
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
export VPCID=$(ibmcloud is vpc-create ${prefix}${basename} --json | jq -r '.id')

vpcResourceAvailable vpcs ${prefix}${basename}


export SUB_FRONT=$(ibmcloud is subnet-create ${prefix}${basename}-frontend-subnet $VPCID $zone --ipv4-cidr-block $cidrBlock --json)
export SUB_FRONT_ID=$(echo "$SUB_FRONT" | jq -r '.id')
echo "Success"



vpcResourceAvailable subnets ${prefix}${basename}-backend-subnet
vpcResourceAvailable subnets ${prefix}${basename}-frontend-subnet


export SGFRONT=$(ibmcloud is security-group-create ${prefix}${basename}-frontend-sg $VPCID --json | jq -r '.id')

vpcResourceAvailable security-groups ${prefix}${basename}-backend-sg
vpcResourceAvailable security-groups ${prefix}${basename}-frontend-sg

#ibmcloud is security-group-rule-add GROUP_ID DIRECTION PROTOCOL
echo "Creating rules"
ibmcloud is security-group-rule-add $SGFRONT inbound tcp --remote "0.0.0.0/0" --port-min 80 --port-max 80 > /dev/null
ibmcloud is security-group-rule-add $SGFRONT inbound tcp --remote "0.0.0.0/0" --port-min 443 --port-max 443 > /dev/null
ibmcloud is security-group-rule-add $SGFRONT inbound tcp --remote "0.0.0.0/0" --port-min 22 --port-max 22 > /dev/null
ibmcloud is security-group-rule-add $SGFRONT outbound tcp --remote "0.0.0.0/0" --port-min 80 --port-max 80 > /dev/null
ibmcloud is security-group-rule-add $SGFRONT outbound tcp --remote "0.0.0.0/0" --port-min 443 --port-max 443 > /dev/null
ibmcloud is security-group-rule-add $SGFRONT outbound tcp --remote "0.0.0.0/0" --port-min 22 --port-max 22 > /dev/null


# Frontend and backend server
echo "Creating VSIs"
export FRONT_VSI=$(ibmcloud is instance-create ${prefix}${basename}-frontend-vsi $VPCID $zone b-2x8 $SUB_FRONT_ID 1000 --image-id $UbuntuImage --key-ids $SSHKey --security-group-ids $SGFRONT  --json)
export FRONT_VSI_NIC_ID=$(echo "$FRONT_VSI" | jq -r '.primary_network_interface.id')

vpcResourceAvailable instances ${prefix}${basename}-frontend-vsi
# Floating IP for frontend
export FRONT_IP_ADDRESS=$(ibmcloud is floating-ip-reserve ${prefix}${basename}-frontend-ip --nic-id $FRONT_VSI_NIC_ID | jq -r '.address')

echo "Your frontend IP address: $FRONT_IP_ADDRESS"
