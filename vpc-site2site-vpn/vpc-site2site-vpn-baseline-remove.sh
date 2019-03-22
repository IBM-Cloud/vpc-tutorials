#!/bin/bash
#set -ex

# Script to selectively delete VPC resources for an IBM Cloud solution tutorial
#
# (C) 2019 IBM
#
# Written by Henrik Loeser, hloeser@de.ibm.com

# include common functions
. $(dirname "$0")/../scripts/common-cleanup-functions.sh

# Set the VPC name accordingly
if [ -z "$REUSE_VPC" ]; then
    vpcname=$BASENAME
else
    vpcname=$REUSE_VPC
fi

# Define patterns to pass on to delete functions
VSI_TEST="${BASENAME}-(onprem|cloud|bastion)-vsi"
SG_TEST="${BASENAME}-(bastion-sg|maintenance-sg|sg)"
SUBNET_TEST="${BASENAME}-(onprem|cloud|bastion)-subnet"
GW_TEST="${BASENAME}-(onprem|cloud|bastion)-gw"

# Delete virtual server instances
echo "Delete VSIs"
deleteVSIsInVPCByPattern $vpcname $VSI_TEST

# Delete security groups and their rules (except default SG on VPC)
echo "Delete Security Groups and Rules"
deleteSGsInVPCByPattern $vpcname $SG_TEST

# Delete subnets
echo "Deleting Subnets"
deleteSubnetsInVPCByPattern $vpcname $SUBNET_TEST

# Delete public gateways
echo "Deleting Public Gateways"
deletePGWsInVPCByPattern $vpcname $GW_TEST