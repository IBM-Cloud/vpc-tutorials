#!/bin/bash
set -e
set -o pipefail
set -x

ZONE=$(ibmcloud is zones $REGION --json | jq -r .[].name | sort | head -n 1)
echo "Region is $REGION, zone is $ZONE"

export BASENAME="automated-tests-${JOB_ID}"
export SSHKEYNAME=$KEYS
export RESOURCE_GROUP_NAME=$RESOURCE_GROUP
export ONPREM_SSH_CIDR=0.0.0.0/0
export PRESHARED_KEY="20_PRESHARED_KEY_KEEP_SECRET_19_$JOB_ID"
export ZONE_ONPREM=$ZONE
export ZONE_CLOUD=$ZONE
export ZONE_BASTION=$ZONE

env | sort

export CONFIG_FILE=none
./vpc-site2site-vpn/vpc-site2site-vpn-baseline-create.sh
./vpc-site2site-vpn/vpc-vpn-create.sh
