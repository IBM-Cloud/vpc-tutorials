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


# Obtain all instances for VPC
export VSI_IDs=$(ibmcloud is instances --json |\
       jq -c '[.[] | select (.vpc.name=="'${vpcname}'") | {id: .id, name: .name}]')


echo "$VSI_IDs" | jq -c -r '.[] | [.id] | @tsv' | while read vsiid
do
    # delete but do not wait to have parallel processing of deletes
    deleteVSIbyID $vsiid false
done

# Loop over VSIs again once more to check the status
echo "$VSI_IDs" | jq -c -r '.[] | [.id,.name] | @tsv ' | while read vsiid name
do
    vpcResourceDeleted instance $vsiid
done




# To delete the security groups we have to consider
# 1) Do not touch the default SG
# 2) First, delete all rules because of cross references
# 3) Then, delete the SGs

export DEF_SG_ID=$(ibmcloud is vpcs --json | jq -r '.[] | select (.name=="'${vpcname}'") | .default_security_group.id')

# Delete the non-default SGs
VPC_SGs=$(ibmcloud is security-groups --json)
echo "$VPC_SGs" | jq -r '.[] | select (.vpc.name=="'${vpcname}'" and .id!="'$DEF_SG_ID'") | [.id,.name] | @tsv' | while read sgid sgname
do
    deleteRulesForSecurityGroupByID $sgid false
    echo "Deleting security group $sgname with id $sgid"
done    
echo "$VPC_SGs" | jq -r '.[] | select (.vpc.name=="'${vpcname}'" and .id!="'$DEF_SG_ID'") | [.id,.name] | @tsv' | while read sgid sgname
do
    echo "Deleting security group $sgname with id $sgid"
    deleteSecurityGroupByID $sgid true
done    


# Delete subnets
# 1) VPN gateways
# 2) Floating IPs
# 3) Subnets
# 4) Public gateways
ibmcloud is subnets --json | jq -r '.[] | select (.vpc.name=="'${vpcname}'") | [.id,.public_gateway?.id] | @tsv' | while read subnetid pgid
do
    deleteSubnetbyID $subnetid $pgid
done

# Delete public gateways
ibmcloud is public-gateways --json | jq -r '.[] | select (.vpc.name=="'${vpcname}'") | [.id,.name] | @tsv' | while read pgid pgname
do
    echo "Deleting public gateway with id $pgid and name $pgname"
    ibmcloud is public-gateway-delete $pgid -f
    vpcResourceDeleted public-gateway $pgid
done

# Once the above is cleaned up, the VPC should be empty.
#
# Delete VPC
ibmcloud is vpcs --json | jq -r '.[] | select (.name=="'${vpcname}'") | .id' | while read vpcid
do
    echo "Deleting VPC ${vpcname} with id $vpcid"
    ibmcloud is vpc-delete $vpcid -f
    vpcResourceDeleted vpc $vpcid
done
