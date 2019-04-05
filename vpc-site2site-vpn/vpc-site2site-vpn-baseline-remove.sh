#!/bin/bash
#set -ex

# Script to selectively delete VPC resources for an IBM Cloud solution tutorial
# Usage: BASENAME=mybase [REUSE_VPC=myvpc] ./vpc-site2site-vpn-baseline-remove.sh
#
# (C) 2019 IBM
#
# Written by Henrik Loeser, hloeser@de.ibm.com

# Exit on errors
set -e
set -o pipefail

# include common functions
. $(dirname "$0")/../scripts/common-cleanup-functions.sh

# Set the VPC name accordingly
if [ -z "$BASENAME" ]; then
    echo "BASENAME needs to be passed in"
    exit
fi

if [ -z "$REUSE_VPC" ]; then
    vpcname=$BASENAME
else
    vpcname=$REUSE_VPC
fi

# Define patterns to pass on to delete functions
VSI_TEST="${BASENAME}-(onprem|cloud|bastion)-vsi"
SG_TEST="${BASENAME}-(bastion-sg|maintenance-sg|sg)"
SUBNET_TEST="${BASENAME}-(onprem|cloud|bastion)-subnet"
GW_TEST="(.)*-pubgw"

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
if [ -z "$REUSE_VPC" ]; then
    echo "Deleting Public Gateways"
    deletePGWsInVPCByPattern $vpcname $GW_TEST
else
    echo "Keeping public gateways with VPC as instructed"
fi
