#!/bin/bash

# Script to set up a VPN connection into a VPC
#
# (C) 2019 IBM
#
# Written by Henrik Loeser, hloeser@de.ibm.com


if [ -z "$2" ]; then 
    echo "usage: $0 vpc-name subnet-name"
    echo "Creates a VPN for the specified subnet"         
    exit
fi

function vpcResourceAvailable {
    until ibmcloud is $1 --json | jq -c '.[] | select (.name=="'$2'" and .status=="available") | [.status,.name]' > /dev/null
    do
        sleep 10
    done        
    echo "$2 became available"
}

function vpcResourceAvailableByID {
    until ibmcloud is $1 --json | jq -c 'select (.id=="'$2'" and .status=="available") | [.status,.name]' > /dev/null
    do
        sleep 10
    done        
    echo "$2 became available"
}


export inputVpcname=$1
export subnetName=$2

export basename="vpn"
export prefix="henrik"
export vpcname="$inputVpcname"
export fullsubnetname="$vpcname-$subnetName-subnet"



export IKE_ID=$(ibmcloud is ike-policy-create $prefix-$basename-ike-policy sha1 2 aes256 1 --key-lifetime 86400 --json | jq -r '.id')

export IPSEC_ID=$(ibmcloud is ipsec-policy-create ${prefix}-${basename}-ipsec-policy sha1 aes256 disabled --key-lifetime 3600 --json | jq -r '.id')

export SUBNET_ID=$(ibmcloud is subnets --json | jq -r '.[] | select (.vpc.name=="'${vpcname}'" and .name=="'${fullsubnetname}'") | .id ')

export GW_ID=$(ibmcloud is vpn-gateway-create "${prefix}-${basename}-gateway" $SUBNET_ID --json | jq -r '.id')

vpcResourceAvailableByID vpn-gateway $GW_ID

ibmcloud is vpn-gateway-connection-create ${prefix}-${basename}-gateway-conn $GW_ID\
    192.168.0.100 HENRIKTEST -admin-state-up true --ike-policy $IKE_ID --ipsec-policy $IPSEC_ID --local-cidrs 192.168.0.0/24 --peer-cidrs 192.168.0.0/24