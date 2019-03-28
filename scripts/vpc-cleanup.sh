#!/bin/bash

# Script to clean up VPC resources
#
# (C) 2019 IBM
#
# Written by Henrik Loeser, hloeser@de.ibm.com

# include common cleanup functions (includes common.sh)
. $(dirname "$0")/../scripts/common-cleanup-functions.sh


if [ -z "$1" ]; then 
    echo "usage: $0 vpc-name"
    echo "Removes a VPC and its related resources"         
    exit
fi
export vpcname=$1

if [ -z "$2" ]; then 
  echo "Are you sure to delete VPC $vpcname and its related resources? [yes/NO]"
  read confirmation
else
  confirmation=$2
fi

if [[ "$confirmation" = "yes" || "$confirmation" = "YES" ]]; then
    echo "ok, going ahead..."
else
    echo "exiting..."
    exit
fi

# Start the actual cleanup processing for a given VPC name
# 1) Loop over VSIs
# 2) Delete the security groups
# 3) Remove the subnets and their related resources
# 4) Delete the VPC itself

# Define patterns to pass on to delete functions
VSI_TEST="(.)*"
SG_TEST="(.)*"
SUBNET_TEST="(.)*"
GW_TEST="(.)*"
LB_TEST="(.)*"

# Delete virtual server instances
echo "Deleting VSIs"
deleteVSIsInVPCByPattern $vpcname $VSI_TEST

# Delete security groups and their rules (except default SG on VPC)
echo "Deleting Security Groups and Rules"
deleteSGsInVPCByPattern $vpcname $SG_TEST

# Delete Load Balancers
echo "Deleting Load Balancers"
deleteLoadBalancersInVPCByPattern $vpcname $LB_TEST

# Delete subnets
echo "Deleting Subnets"
deleteSubnetsInVPCByPattern $vpcname $SUBNET_TEST

# Delete public gateways
echo "Deleting Public Gateways"
deletePGWsInVPCByPattern $vpcname $GW_TEST


# Once the above is cleaned up, the VPC should be empty.
#
# Delete VPC
ibmcloud is vpcs --json | jq -r '.[] | select (.name=="'${vpcname}'") | .id' | while read vpcid
do
    echo "Deleting VPC ${vpcname} with id $vpcid"
    ibmcloud is vpc-delete $vpcid -f
    vpcResourceDeleted vpc $vpcid
done
