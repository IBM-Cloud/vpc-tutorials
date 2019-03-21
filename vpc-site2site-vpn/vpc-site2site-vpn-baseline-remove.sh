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

VSI_IDs=$(ibmcloud is instances --json | jq -c '[.[] | select(.vpc.name=="'${vpcname}'") | select(.name | test("'${BASENAME}'-(onprem|bastion|cloud)-vsi")) | {id: .id, name: .name}]')


# Obtain all instances for VPC

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
