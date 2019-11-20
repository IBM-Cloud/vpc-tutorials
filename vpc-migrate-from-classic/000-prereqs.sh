#!/bin/bash
set -e

echo ">>> Targeting resource group $RESOURCE_GROUP_NAME..."
ibmcloud target -g $RESOURCE_GROUP_NAME

if [ -z "$TARGET_GENERATION" ]; then
  TARGET_GENERATION=1
fi

echo ">>> Setting VPC Gen for compute to $TARGET_GENERATION..."
if ibmcloud is >/dev/null; then
  ibmcloud is target --gen $TARGET_GENERATION
else
  echo "Make sure vpc-infrastructure plugin is properly installed with ibmcloud plugin install vpc-infrastructure."
  exit 1
fi

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

if [ "$TARGET_GENERATION" = "2" ]; then
  echo ">>> Is qemu-img (https://www.qemu.org/download/) installed?"
  qemu-img --version
fi

