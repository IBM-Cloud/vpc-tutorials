#!/bin/bash
set -ex

if [ -z "$3" ]; then 
              echo usage: $0 prefix subnet0Name subnet1Name
              exit
fi
export prefix=$1
export subnet0Name=$2
export subnet1Name=$3

function vpcResourceAvailable {
    until ibmcloud is $1 --json | jq -c '.[] | select (.name=="'$2'" and .status=="available") | [.status,.name]' > /dev/null
    do
        sleep 10
    done        
    echo "$2 became available"
}


subnet0=$(ibmcloud is subnets --json  | jq '.[] | select(.name=="'$subnet0Name'")')
subnet0Id=$(echo $subnet0 | jq -r '.id')
subnet0Cidr=$(echo $subnet0 | jq -r '.ipv4_cidr_block')
vpn0=$(ibmcloud is vpn-gateway-create ${prefix}0 $subnet0Id --json)
echo $vpn0
vpn0Id=$(echo $vpn0 | jq -r '.id')
echo $vpn0Id

subnet1=$(ibmcloud is subnets --json  | jq '.[] | select(.name=="'$subnet1Name'")')
subnet1Id=$(echo $subnet1 | jq -r '.id')
subnet1Cidr=$(echo $subnet1 | jq -r '.ipv4_cidr_block')
vpn1=$(ibmcloud is vpn-gateway-create ${prefix}1 $subnet1Id --json)
echo $vpn1
vpn1Id=$(echo $vpn1 | jq -r '.id')
echo $vpn1Id

vpcResourceAvailable vpn-gateways ${prefix}0
vpcResourceAvailable vpn-gateways ${prefix}1

# the ip address is not available as the return value from the create, now it is available
vpn0=$(ibmcloud is vpn-gateway $vpn0Id --json)
vpn1=$(ibmcloud is vpn-gateway $vpn1Id --json)

vpn0Ip=$(echo $vpn0 | jq -r '.public_ip.address')
vpn1Ip=$(echo $vpn1 | jq -r '.public_ip.address')

vpnGatewayConnection0=$(ibmcloud is vpn-gateway-connection-create ${prefix}0vpn $vpn0Id $vpn1Ip 'PRESHARED_KEY' --local-cidrs $subnet0Cidr --peer-cidrs $subnet1Cidr --json)
vpnGatewayConnection1=$(ibmcloud is vpn-gateway-connection-create ${prefix}1vpn $vpn1Id $vpn0Ip 'PRESHARED_KEY' --local-cidrs $subnet1Cidr --peer-cidrs $subnet0Cidr --json)
echo $vpnGatewayConnection

