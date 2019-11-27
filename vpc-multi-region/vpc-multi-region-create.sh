#!/bin/bash

# Script to create VPC resources for an IBM Cloud solution tutorial
#
# (C) 2019 IBM
#
# Written by Vidyasagar Machupalli

# Exit on errors
set -e
set -o pipefail

# Load up .env
set -a # automatically export all variables
source .env
set +a

for (( i=0; i < ${#VPC_REGIONS[@]}; i++ )); do
    region=${VPC_REGIONS[$i]}
    name=${VPC_NAMES[$i]}
    ./vpc-multi-region-single-create.sh $region $name
done
( cd cis && ./cis-glb-create.sh)
