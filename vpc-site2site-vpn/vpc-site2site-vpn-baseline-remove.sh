#!/bin/bash
#set -ex

# Script to deploy VPC resources for an IBM Cloud solution tutorial
#
# (C) 2019 IBM
#
# Written by Henrik Loeser, hloeser@de.ibm.com

# include configuration
#. $(dirname "$0")/config.sh

# include common functions
. $(dirname "$0")/../scripts/common-cleanup-functions.sh


vpcname=$REUSE_VPC
VSI_TEST="${BASENAME}-(onprem|cloud|bastion)-vsi"
SG_TEST="${BASENAME}-(bastion-sg|maintenance-sg|sg)"
SUBNET_TEST="${BASENAME}-(onprem|cloud|bastion)-subnet"
GW_TEST="${BASENAME}-(onprem|cloud|bastion)-gw"


VSI_IDs=$(ibmcloud is instances --json | jq -c '[.[] | select(.vpc.name=="'${vpcname}'") | select(.name | test("'${VSI_TEST}'")) | {id: .id, name: .name}]')


# Obtain all instances for VPC
echo "Deleting VSIs"
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


DEF_SG_ID=$(ibmcloud is vpcs --json | jq -r '.[] | select (.name=="'${vpcname}'") | .default_security_group.id')

# Delete the non-default SGs
VPC_SGs=$(ibmcloud is security-groups --json)
echo "Deleting Rules on Security Groups"
echo "$VPC_SGs" | jq -r '.[] | select (.vpc.name=="'${vpcname}'" and .id!="'$DEF_SG_ID'") |select(.name | test("'${SG_TEST}'")) | [.id,.name] | @tsv' | while read sgid sgname
do
    deleteRulesForSecurityGroupByID $sgid false
done    
echo "Deleting Security Groups"
echo "$VPC_SGs" | jq -r '.[] | select (.vpc.name=="'${vpcname}'" and .id!="'$DEF_SG_ID'") |select(.name | test("'${SG_TEST}'")) | [.id,.name] | @tsv' | while read sgid sgname
do
    echo "Deleting security group $sgname with id $sgid"
    deleteSecurityGroupByID $sgid true
done    


# Delete subnets
echo "Deleting Subnets"
ibmcloud is subnets --json | jq -r '.[] | select (.vpc.name=="'${vpcname}'") | select(.name | test("'${SUBNET_TEST}'"))  | [.id,.public_gateway?.id] | @tsv' | while read subnetid pgid
do
    deleteSubnetbyID $subnetid $pgid
done

# Delete public gateways
echo "Deleting Public Gateways"
ibmcloud is public-gateways --json | jq -r '.[] | select (.vpc.name=="'${vpcname}'") |select(.name | test("'${GW_TEST}'")) | [.id,.name] | @tsv' | while read pgid pgname
do
    echo "Deleting public gateway with id $pgid and name $pgname"
    ibmcloud is public-gateway-delete $pgid -f
    vpcResourceDeleted public-gateway $pgid
done