#!/bin/bash

# Script related to an IBM Cloud solution tutorial
# Enable / disable the maintenance security group
#
# (C) 2019 IBM
#
# Written by Henrik Loeser, hloeser@de.ibm.com

# Exit on errors
set -e
set -o pipefail

if [ -z "$3" ]; then 
              echo "usage: $0 vpc-name instance-name (on | off)"
              exit
fi

ACTION=$3
INSTANCE=$2
VPCNAME=$1



# Obtain NIC ID for instance
export NICID=$(ibmcloud is instances --output json |\
       jq -c -r '.[] | select (.vpc.name=="'${VPCNAME}'" and .name=="'${INSTANCE}'") | .primary_network_interface.id')

export SGMAINT=$(ibmcloud is security-groups --output json |\
       jq -c -r '.[] | select (.vpc.name=="'${VPCNAME}'" and .name=="'${VPCNAME}'-maintenance-sg") | .id')

if [ $ACTION = "on" ]; then
    ibmcloud is security-group-network-interface-add $SGMAINT $NICID
fi
if [ $ACTION = "off" ]; then
    ibmcloud is security-group-network-interface-remove $SGMAINT $NICID
fi
