#!/bin/bash

# Script to clean up VPC resources for an IBM Cloud solution tutorial
#
# (C) 2019 IBM
#
# Written by Henrik Loeser, hloeser@de.ibm.com

# Exit on errors
set -e
set -o pipefail

if [ -z "$1" ]; then 
    export prefix=""
else
    export prefix=$1
fi    

# include common functions
. $(dirname "$0")/../scripts/common-cleanup-functions.sh

export basename="vpc-pubpriv"
export BASENAME="${prefix}${basename}"

# Set the VPC name accordingly
if [ -z "$REUSE_VPC" ]; then
    vpcname=$BASENAME
else
    vpcname=$REUSE_VPC
fi

# Define patterns to pass on to delete functions
VSI_TEST="${BASENAME}-(backend|frontend|bastion)-vsi"
SG_TEST="${BASENAME}-(backend-sg|frontend-sg|maintenance-sg|bastion-sg)"
SUBNET_TEST="${BASENAME}-(backend|frontend|bastion)-subnet"
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
