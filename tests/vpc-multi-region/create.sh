#!/bin/bash

# create the VPC that will be reused by the following scripts
ibmcloud is vpc-create $TEST_VPC_NAME
export REUSE_VPC=$TEST_VPC_NAME

# All resources will be prefixed by this basename
export BASENAME=at$JOB_ID

# name of the ssh key that will be used for instance creation - create this in advance in the cloud
export KEYNAME=$KEYS

# set this to the resource group
export RESOURCE_GROUP_NAME=$RESOURCE_GROUP

# certificate CRN of the Domain under Certificate Manager service > `Manage`
export CERTIFICATE_CRN=
#'unset'

touch .env
./vpc-multi-region/vpc-multi-region-single-create.sh $REGION