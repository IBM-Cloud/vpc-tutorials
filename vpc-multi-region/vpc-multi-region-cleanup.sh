#!/bin/bash

# Script to delete CIS and VPC resources for an IBM Cloud solution tutorial
#
# (C) 2019 IBM
#
# Written by Vidyasagar Machupalli

# Exit on errors
# Exit on errors
set -e
set -o pipefail

source .env

echo "Deleting CIS GLB resources...."
( cd cis && ./cis-glb-cleanup.sh )

echo "Deleting VPC resources..."
for (( i=0; i < ${#VPC_REGIONS[@]}; i++ )); do
    region=${VPC_REGIONS[$i]}
    name=${VPC_NAMES[$i]}
    ibmcloud target -r $region
    ../scripts/vpc-cleanup.sh $name -f
done
