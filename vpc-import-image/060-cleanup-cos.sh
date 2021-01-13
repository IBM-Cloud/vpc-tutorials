#!/bin/bash

# include common functions
#my_dir=$(dirname "$0")
#source $my_dir/../scripts/common.sh

if ! json=$(ibmcloud resource service-instance $COS_SERVICE_NAME --output json); then
  echo ">>> COS service $COS_SERVICE_NAME not found..."
  exit 0
fi

cosGuid=$(echo "$json" | jq -r '.[]|.guid')
if policyId=$(ibmcloud iam authorization-policies --output json | jq -e -r '.[]
  | select(.subjects[].attributes[].value=="is")
  | select(.subjects[].attributes[].value=="image")
  | select(.resources[].attributes[].value=="'$cosGuid'")
  | select(.roles[].display_name=="Reader")
  | select(.resources[].attributes[].value=="cloud-object-storage")
  | .id'); then
    echo ">>> Delete reader policy between vpc image service and COS service $COS_SERVICE_NAME ..."
    ibmcloud iam  authorization-policy-delete $policyId --force
else
  echo "Reader policy between VPC image service and COS does not exist"
fi

echo ">>> Delete COS service $COS_SERVICE_NAME ..."
ibmcloud resource service-instance-delete $COS_SERVICE_NAME --force --recursive

