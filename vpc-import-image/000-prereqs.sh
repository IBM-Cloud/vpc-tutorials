#!/bin/bash
set -e

# include common functions
source $(dirname "$0")/../scripts/common.sh

echo ">>> Targeting resource group $RESOURCE_GROUP_NAME..."
ibmcloud target -g $RESOURCE_GROUP_NAME

echo ">>> Setting VPC Gen for compute..."
if ibmcloud is >/dev/null; then
  echo "is plugin is OK"
else
  echo "Make sure vpc-infrastructure plugin is properly installed with ibmcloud plugin install vpc-infrastructure."
  exit 1
fi

echo ">>> Verify the vpc ssh key configured exists, looking for the id for $VPC_SSH_KEY_NAME..."
ibmcloud is keys --output json | jq -e -r '.[]|select(.name=="'$VPC_SSH_KEY_NAME'")|.id'

echo ">>> Ensuring Cloud Object Storage plugin is installed"
if ibmcloud cos config list >/dev/null; then
  echo "cloud-object-storage plugin is OK"
  # clear any default crn as it could prevent COS calls to work
  ibmcloud cos config crn --crn "" --force
else
  echo "Make sure cloud-object-storage plugin is properly installed with ibmcloud plugin install cloud-object-storage."
  exit 1
fi

echo ">>> Is terraform installed?"
terraform version

echo ">>> Is jq (https://stedolan.github.io/jq/) installed?"
jq -V

echo ">>> Is curl installed?"
curl -V

echo ">>> is shasum installed?"
sha256_wrapper --version
