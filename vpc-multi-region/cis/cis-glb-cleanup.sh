#!/bin/bash

# Exit on errors
set -e
set -o pipefail

# Load up .env
set -a # automatically export all variables
source ../.env
set +a

echo "Deleting Global Load Balancer..."
DOMAIN_ID=$(ibmcloud cis domains -i $INSTANCE_NAME --output json | jq -r '.[].id')
DOMAIN_NAME=$(ibmcloud cis domains -i $INSTANCE_NAME --output json | jq -r '.[].name')
export GLBS=$(ibmcloud cis glbs $DOMAIN_ID -i $INSTANCE_NAME --output json)
GLB_ID=$(echo "$GLBS" | jq -r '.[] | select(.name=="lb.'$DOMAIN_NAME'") .id')
ibmcloud cis glb-delete $DOMAIN_ID $GLB_ID -i $INSTANCE_NAME

POOLID=$(echo "$GLBS" | jq -r '.[] | select(.name=="lb.'$DOMAIN_NAME'").default_pools[0]')
MONITORID=$(ibmcloud cis glb-pool $POOLID -i $INSTANCE_NAME --output json | jq -r '.monitor')

echo "Deleting pools..."
echo "$GLBS" | jq -c -r '.[] | select(.name=="lb.'$DOMAIN_NAME'").default_pools[]' | while read poolid;
do
    ibmcloud cis glb-pool-delete $poolid -i $INSTANCE_NAME
done
echo "Deleting health monitor..."
ibmcloud cis glb-monitor-delete $MONITORID -i $INSTANCE_NAME 
