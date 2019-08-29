#!/bin/bash
set -e
set -o pipefail

# include common functions
. $(dirname "$0")/../scripts/common.sh

if check_exists "$(ibmcloud resource service-instance $COS_SERVICE_NAME 2>&1)"; then
  echo "Cloud Object Storage service $COS_SERVICE_NAME already exists"
else
  echo "Creating Cloud Object Storage Service..."
  ibmcloud resource service-instance-create $COS_SERVICE_NAME \
    cloud-object-storage "$COS_SERVICE_PLAN" global || exit 1
fi

COS_INSTANCE_ID=$(get_instance_id $COS_SERVICE_NAME)
COS_GUID=$(get_guid $COS_SERVICE_NAME)
check_value "$COS_INSTANCE_ID"
check_value "$COS_GUID"

# Create the bucket
if ibmcloud cos head-bucket --bucket $COS_BUCKET_NAME --region $COS_REGION > /dev/null 2>&1; then
  echo "Bucket already exists"
else
  echo "Creating storage bucket $COS_BUCKET_NAME"
  ibmcloud cos create-bucket \
    --bucket $COS_BUCKET_NAME \
    --ibm-service-instance-id $COS_INSTANCE_ID \
    --region $COS_REGION
fi

EXISTING_POLICIES=$(ibmcloud iam authorization-policies --output JSON)
check_value "$EXISTING_POLICIES"

# Create a policy to make serviceID a writer for Key Protect
if echo "$EXISTING_POLICIES" | \
  jq -e '.[] | select(.subjects[].attributes[].value=="is")' | \
  jq -e -s '.[] | select(.subjects[].attributes[].value=="image")' | \
  jq -e -s '.[] | select(.roles[].display_name=="Reader")' | \
  jq -e -s '.[] | select(.resources[].attributes[].value=="cloud-object-storage")' | \
  jq -e -s '.[] | select(.resources[].attributes[].value=="'$COS_GUID'")' > /dev/null; then
  echo "Reader policy between VPC image service and COS already exists"
else
  ibmcloud iam authorization-policy-create \
    is \
    cloud-object-storage \
    Reader \
    --source-resource-type image \
    --target-service-instance-id $COS_GUID
fi
