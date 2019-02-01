#!/bin/bash

# Script to clean up a VPN connection into a VPC
#
# (C) 2019 IBM
#
# Written by Henrik Loeser, hloeser@de.ibm.com

export basename="vpn"
export prefix="henrik"

function vpcResourceDeleted {
    COUNTER=0
    while ibmcloud is $1 $2 $3 $4 > /dev/null 2>/dev/null
    do
        echo "waiting"
        sleep 20
        let COUNTER=COUNTER+1
        if [ $COUNTER -gt 25 ]; then
            echo "timeout"
            exit
        fi
    done        
    echo "$1 $2 $3 $4 went away"
}


export GW_ID=$(ibmcloud is vpn-gateways --json | jq -c -r '.[] | select (.name=="'${prefix}'-'${basename}'-gateway") | .id')
if [ $$GW_ID ]; then
    echo "Gateway: $GW_ID"
    #export GW_CONN_ID=$(ibmcloud is vpn-gateway-connections $GW_ID --json | jq -c -r '.[] | select (.name=="'${prefix}'-'${basename}'-gateway") | .id')
    ibmcloud is vpn-gateway-delete $GW_ID -f > /dev/null
    vpcResourceDeleted vpn-gateway $GW_ID
fi

echo "IPSEC Policy"
export IPSEC_ID=$(ibmcloud is ipsec-policies --json | jq -c -r '.[] | select (.name=="'${prefix}'-'${basename}'-ipsec-policy") | .id')
ibmcloud is ipsec-policy-delete $IPSEC_ID -f > /dev/null
vpcResourceDeleted ipsec-policy $IPSEC_ID

echo "IKE Policy"
export IKE_ID=$(ibmcloud is ike-policies --json | jq -c -r '.[] | select (.name=="'${prefix}'-'${basename}'-ike-policy") | .id')
ibmcloud is ike-policy-delete $IKE_ID -f > /dev/null
vpcResourceDeleted ike-policy $IKE_ID
