#!/bin/bash
set -e

echo ">>> login using apikey target resource group and region..."
ibmcloud login --apikey $IBMCLOUD_API_KEY -g $RESOURCE_GROUP_NAME -r $REGION

echo ">>> Setting VPC Gen for compute..."
if ibmcloud is >/dev/null; then
  ibmcloud is target --gen 2
else
  echo "Make sure vpc-infrastructure plugin is properly installed with ibmcloud plugin install vpc-infrastructure."
  exit 1
fi

echo ">>> Is terraform installed?"
terraform version

echo ">>> Is terraform a good version?"
(
	cd terraform
	terraform init
)

echo ">>> Is jq (https://stedolan.github.io/jq/) installed?"
jq -V

echo ">>> Is curl installed?"
curl -V

echo ">>> check version of ibmcloud cli that is >= 1.5.0"
ibmcloud version
