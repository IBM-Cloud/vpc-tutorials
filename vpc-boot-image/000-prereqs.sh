#!/bin/bash
set -e

echo ">>> Targeting resource group $RESOURCE_GROUP_NAME..."
ibmcloud target -g $RESOURCE_GROUP_NAME

echo ">>> login using apikey..."
ibmcloud login --apikey $IBMCLOUD_API_KEY

echo ">>> Targeting region $REGION..."
ibmcloud target -r $REGION

echo ">>> Targeting resource group $RESOURCE_GROUP_NAME..."
ibmcloud target -g $RESOURCE_GROUP_NAME

echo ">>> Setting VPC Gen for compute..."
if ibmcloud is >/dev/null; then
  ibmcloud is target --gen 2
else
  echo "Make sure vpc-infrastructure plugin is properly installed with ibmcloud plugin install vpc-infrastructure."
  exit 1
fi

echo ">>> Is terraform installed?"
terraform version

echo ">>> Is jq (https://stedolan.github.io/jq/) installed?"
jq -V

echo ">>> Is curl installed?"
curl -V
