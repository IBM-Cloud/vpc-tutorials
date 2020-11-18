#!/bin/bash

# Script to clean up VPC resources
#
# (C) 2019 IBM
#
# Written by Henrik Loeser, hloeser@de.ibm.com


# Exit on errors
set -e
set -o pipefail

# include common cleanup functions (includes common.sh)
. $(dirname "$0")/../scripts/common-cleanup-functions.sh


if [ -z "$1" ]; then 
    echo "usage: $0 vpc-name [--keep true] [--prefix pattern] [-f, --force]"
    echo "Removes a VPC and its related resources"
    echo "  --keep true         Keep the VPC and only delete resources within"
    echo "  --prefix pattern    Only delete resources with names starting with specified pattern"
    echo "  --force, -f         Force the operation without confirmation"
    exit
fi
export vpcname=$1

PREFIX=""

POSITIONAL=()
while [[ $# -gt 1 ]]
do
key="$2"

case $key in
    -f|--force)
    FORCE=true
    echo "FORCE cleanup"
    shift # past argument
    ;;
    --keep)
    KEEP="$3"
    echo "KEEP: ${KEEP}"
    shift # past argument
    shift # past value
    ;;
    --prefix)
    PREFIX="$3"
    echo "PREFIX: ${PREFIX}"
    shift # past argument
    shift # past value
    ;;
    *)    # unknown option
    POSITIONAL+=("$2") # save it in an array for later
    shift # past argument
    ;;
esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters

if [ "$FORCE" != "true" ]; then 
  echo "Are you sure to delete VPC $vpcname and its related resources? [yes/NO]"
  read confirmation
else
  confirmation="yes"
fi

if [[ "$confirmation" = "yes" || "$confirmation" = "YES" ]]; then
    echo "ok, going ahead..."
else
    echo "exiting..."
    exit
fi

VPCs=$(ibmcloud is vpcs --json)
vpcId=$(echo "${VPCs}" | jq -r '.[] | select (.name=="'${vpcname}'") | .id')

# Start the actual cleanup processing for a given VPC name
# 1) Loop over VSIs
# 2) Delete the security groups
# 3) Remove the subnets and their related resources
# 4) Delete the VPC itself

# Define patterns to pass on to delete functions
VSI_TEST="${PREFIX}(.)*"
SG_TEST="${PREFIX}(.)*"
SUBNET_TEST="${PREFIX}(.)*"
GW_TEST="${PREFIX}(.)*"
LB_TEST="${PREFIX}(.)*"
IG_TEST="${PREFIX}(.)*"
IT_TEST="${PREFIX}(.)*"

# Delete instance groups
deleteInstanceGroupsInVPCByPattern $vpcname $IG_TEST

# Delete instance templates
deleteInstanceTemplatesInVPCByPattern $vpcId $IT_TEST

# Delete virtual server instances
echo "Deleting VSIs"
deleteVSIsInVPCByPattern $vpcname $VSI_TEST

# Delete security groups and their rules (except default SG on VPC)
# echo "Deleting Security Groups and Rules"
# security groups will be deleted as a side effect of deleting the vpc
#deleteSGsInVPCByPattern $vpcname $SG_TEST

# Delete Load Balancers
echo "Deleting Load Balancers"
deleteLoadBalancersInVPCByPattern $vpcname $LB_TEST

# Delete subnets
echo "Deleting Subnets"
deleteSubnetsInVPCByPattern $vpcname $SUBNET_TEST

# Delete public gateways
if [ "$KEEP" == "true" ]; then
    echo "Keeping public gateways with VPC as instructed"
else
    echo "Deleting Public Gateways"
    deletePGWsInVPCByPattern $vpcname $GW_TEST
fi


# Once the above is cleaned up, the VPC should be empty.
#
# Delete VPC if not keeping it
if [ "$KEEP" == "true" ]; then
    echo "Keeping VPC as instructed"
else
    VPCs=$(ibmcloud is vpcs --json)
    echo "${VPCs}" | jq -r '.[] | select (.name=="'${vpcname}'") | .id' | while read vpcid
    do
        echo "Deleting VPC ${vpcname} with id $vpcid"
        ibmcloud is vpc-delete $vpcid -f
        vpcResourceDeleted vpc $vpcid
    done
fi
