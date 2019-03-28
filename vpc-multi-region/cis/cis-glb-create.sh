#!/bin/bash

# Load up .env
set -a # automatically export all variables
source ../.env
set +a

echo "Creating required JSON files..."
cp ./json/cis_monitor_template.json ./json/cis_monitor.json
cp ./json/cis_pool_template.json ./json/cis_pool.json
cp ./json/cis_glb_template.json ./json/cis_glb.json

# Updating Domain ID and Name
DOMAIN_ID=$(ibmcloud cis domains -i $INSTANCE_NAME --output json | jq -r '.[].id')
echo "Domain ID: $DOMAIN_ID"
DOMAIN_NAME=$(ibmcloud cis domains -i $INSTANCE_NAME --output json | jq -r '.[].name')

# Create a Health Monitor
echo "Creating health monitor..."
MONITOR_ID=$(ibmcloud cis glb-monitor-create -j ./json/cis_monitor.json  -i $INSTANCE_NAME --output json | jq -r '.id')
echo "Monitor ID: $MONITOR_ID"

echo "Creating origin pools..."
for REGION in $VPC_REGION_1 $VPC_REGION_2
do
    if [[ "$REGION" == "us-south" ]]; then
        #jq  '.name = "'$BASENAME-$REGION'-pool"' ./json/cis_pool.json >./json/cis_pool.json.tmp && cp ./json/cis_pool.json.tmp ./json/cis_pool.json && rm -rf ./json/cis_pool.json.tmp
        jq '. + {name:"'$BASENAME-$REGION'-pool","description":"Pool in '$REGION'","check_regions":["WNAM"],"monitor":"'$MONITOR_ID'"} | .origins += [{"name":"'$REGION'-pool","address":"'$REGION_US_HOSTNAME'","enabled":true}]' ./json/cis_pool.json >./json/cis_pool.json.tmp && cp ./json/cis_pool.json.tmp ./json/cis_pool.json && rm -rf ./json/cis_pool.json.tmp
        REGION_US_POOLID=$(ibmcloud cis glb-pool-create  -j ./json/cis_pool.json -i $INSTANCE_NAME --output json | jq -r '.id') 
        elif [[ "$REGION" == "eu-de" ]]; then
        jq '. + {name:"'$BASENAME-$REGION'-pool","description":"Pool in '$REGION'","origins":[{"name":"'$REGION'-pool","address":"'$REGION_EU_HOSTNAME'","enabled":true}],"check_regions":["WEU"],"monitor":"'$MONITOR_ID'"}' ./json/cis_pool.json >./json/cis_pool.json.tmp && cp ./json/cis_pool.json.tmp ./json/cis_pool.json && rm -rf ./json/cis_pool.json.tmp 
        REGION_EU_POOLID=$(ibmcloud cis glb-pool-create  -j ./json/cis_pool.json -i $INSTANCE_NAME --output json | jq -r '.id') 
    fi
done

echo "US Pool ID: $REGION_US_POOLID"
echo "EU Pool ID: $REGION_EU_POOLID"
echo "Creating Global Load Balancer..."
 jq '. + {name:"lb.'$DOMAIN_NAME'","fallback_pool":"'$REGION_US_POOLID'","default_pools":["'$REGION_US_POOLID'","'$REGION_EU_POOLID'"],"description":"VPC global load balancer","region_pools":{"WNAM": ["'$REGION_US_POOLID'"],"WEU": ["'$REGION_EU_POOLID'"]}}' ./json/cis_glb.json >./json/cis_glb.json.tmp && cp ./json/cis_glb.json.tmp ./json/cis_glb.json && rm -rf ./json/cis_glb.json.tmp
 GLB_ID=$(ibmcloud cis glb-create $DOMAIN_ID -j ./json/cis_glb.json -i $INSTANCE_NAME --output json | jq -r '.id')
 echo "GLB ID: $GLB_ID"
 echo "Launch your GLB at lb.$DOMAIN_NAME"

rm -rf ./json/cis_monitor.json
rm -rf ./json/cis_pool.json
rm -rf ./json/cis_glb.json