#!/bin/bash
set -e
set -o pipefail
this_dir=$(dirname "$0")
source $this_dir/../tests_common.sh

# authentication
export IBMCLOUD_API_KEY=$API_KEY

# prefix for all resources
export PREFIX=at$JOB_ID

# where to put resources that support resource groups
export RESOURCE_GROUP_NAME=$RESOURCE_GROUP

### Cloud object storage service to store the image
export COS_SERVICE_NAME=$PREFIX-cos
export COS_SERVICE_PLAN=standard
export COS_REGION=$REGION
export COS_BUCKET_NAME=$PREFIX-classic-images

# key to inject in the classic VSI
export SSH_PUBLIC_KEY=$HOME/.ssh/id_rsa.pub
export SSH_PRIVATE_KEY=$HOME/.ssh/id_rsa

### VPC infrastructure

# VPC ssh key name to inject in the migrated VPC VSI
export VPC_SSH_KEY_NAME=$(ssh_key_name_for_job)

cd ./vpc-migrate-from-classic
./060-cleanup.sh
