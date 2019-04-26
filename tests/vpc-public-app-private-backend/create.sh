#!/bin/bash

# deploy to first zone in the selected region
ZONE=$(ibmcloud is zones $REGION --json | jq -r .[].name | sort | head -1)
echo "Region is $REGION, zone is $ZONE"

./vpc-public-app-private-backend/vpc-pubpriv-create-with-bastion.sh $ZONE $KEYS at$JOB_ID- $RESOURCE_GROUP
