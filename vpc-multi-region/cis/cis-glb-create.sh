#!/bin/bash

# Exit on errors
set -e
set -o pipefail

# Load up .env
set -a # automatically export all variables
source ../.env
set +a

echo "Creating required JSON files..."
# Updating Domain ID and Name
DOMAIN_ID=$(ibmcloud cis domains -i $INSTANCE_NAME --output json | jq -r '.[].id')
echo "Domain ID: $DOMAIN_ID"
DOMAIN_NAME=$(ibmcloud cis domains -i $INSTANCE_NAME --output json | jq -r '.[].name')

# Create a Health Monitor
echo "Creating health monitor..."
MONITOR_ID=$(ibmcloud cis glb-monitor-create -j ./json/cis_monitor_template.json  -i $INSTANCE_NAME --output json | jq -r '.id')
ibmcloud cis glb-monitors -i $INSTANCE_NAME --output json 

echo "Monitor ID: $MONITOR_ID"

CIS_REGIONS=(WNAM, WEU)

poolids=()
for i in 0 1; do
  REGION=${VPC_REGIONS[$i]}
  CIS_REGION=${CIS_REGION[$i]}
  NAME=${VPC_NAMES[$i]}
  ibmcloud target -r $REGION
  lbs_json=$(ibmcloud is load-balancers --json)
  LB_HOSTNAME=$(echo "$lbs_json" | jq -r '.[]|select(.name=="'$NAME'-lb")|.hostname')
  pool_json=$(jq '. + {name:"'$NAME'-pool","description":"Pool in '$REGION'","origins":[{"name":"'$REGION'-pool","address":"'$LB_HOSTNAME'","enabled":true}],"check_regions":["WNAM"],"monitor":"'$MONITOR_ID'"}' ./json/cis_pool_template.json) 
  echo "$pool_json" | jq .
  poolids[$i]=$(ibmcloud cis glb-pool-create  --json-str "$pool_json" -i $INSTANCE_NAME --output json | jq -r '.id') 
done
echo ${poolids[*]}

echo "Creating Global Load Balancer..."
 # glb_json=$(jq '. + {name:"lb.'$DOMAIN_NAME'","fallback_pool":"'${poolids[0]}'","default_pools":["'${poolids[0]}'","'${poolids[1]}'"],"description":"VPC global load balancer","region_pools":{"WNAM": ["'${poolids[0]}'"],"WEU": ["'${poolids[1]}'"]}}' ./json/cis_glb_template.json)
 glb_json=$(jq '. + {name:"lb.'$DOMAIN_NAME'","fallback_pool":"'${poolids[0]}'","default_pools":["'${poolids[0]}'","'${poolids[1]}'"],"description":"VPC global load balancer"}' ./json/cis_glb_template.json)
 GLB_ID=$(ibmcloud cis glb-create $DOMAIN_ID --json-str "$glb_json" -i $INSTANCE_NAME --output json | jq -r '.id')
 echo "GLB ID: $GLB_ID"
 echo "curl lb.$DOMAIN_NAME"
