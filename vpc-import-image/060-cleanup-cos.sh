#!/bin/bash

# include common functions
my_dir=$(dirname "$0")
source $my_dir/../scripts/common.sh

ibmcloud resource service-instance-delete $COS_SERVICE_NAME --force --recursive
