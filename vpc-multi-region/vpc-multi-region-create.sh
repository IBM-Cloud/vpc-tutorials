#!/bin/bash

# Script to create VPC resources for an IBM Cloud solution tutorial
#
# (C) 2019 IBM
#
# Written by Vidyasagar Machupalli

# Load up .env
set -a # automatically export all variables
source .env
set +a

# include common functions
#. $(dirname "$0")/../scripts/common.sh
#. $(dirname "$0")/common-load-balancer.sh

for REGION in $VPC_REGION_1 $VPC_REGION_2
do
    ./vpc-multi-region-single-create.sh $REGION
done
