#!/bin/bash

if [ -z "$2" ]; then 
              echo "usage: $0 instance-name (on | off) [prefix]"
              exit
fi

export action=$2

if [ -z "$3" ]; then 
    export prefix=""
else
    export prefix=$3
fi    

export instance=$1
export basename="vpc-pubpriv"



# Obtain NIC ID for instance
export NICID=$(ibmcloud is instances --json |\
       jq -c -r '.[] | select (.vpc.name=="'${prefix}${basename}'" and .name=="'${prefix}${basename}'-'${instance}'-vsi") | .primary_network_interface.id')

export SGMAINT=$(ibmcloud is security-groups --json |\
       jq -c -r '.[] | select (.vpc.name=="'${prefix}${basename}'" and .name=="'${prefix}${basename}'-maintenance-sg") | .id')

if [ $action = "on" ]; then
    ibmcloud is security-group-network-interface-add $SGMAINT $NICID
fi
if [ $action = "off" ]; then
    ibmcloud is security-group-network-interface-remove $SGMAINT $NICID
fi
