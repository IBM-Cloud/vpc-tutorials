#!/bin/bash
source tests/tests_common.sh
source scripts/common.sh

echo ">>> Environment variables:"
env | sort

echo ">>> Running test $TEST"

if [ -z "$API_KEY" ]; then
  echo "Missing API_KEY"
  exit 1
fi

if [ -z "$REGION" ]; then
  echo "Missing REGION"
  exit 1
fi

if [ -z "$RESOURCE_GROUP" ]; then
  echo "Missing RESOURCE_GROUP"
  exit 1
fi

if [ -z "$TEST" ]; then
  echo "Missing TEST"
  exit 1
fi

# allow to force terraform to a specific version
if [ -z "$TERRAFORM_VERSION" ]; then
  export TERRAFORM_VERSION=0.11.14
fi

if [ "$TERRAFORM_VERSION" == "latest" ]; then
  tfswitch -u
else
  tfswitch $TERRAFORM_VERSION
fi

# log in
ibmcloud config --check-version=false
ibmcloud login --apikey $API_KEY -r $REGION -g $RESOURCE_GROUP

if [ "$KEYS" ];
then
  echo "KEYS has been specified in the environment"
else
  echo "KEYS not specified in the environment, will use all existing keys"
  if KEYS_JSON=$(ibmcloud is keys --output json)
  then
    export KEYS=$(echo "${KEYS_JSON}" | jq -r ".[].name" | paste -d, -s)
  else
    echo "Failed to get KEYS: ${KEYS_JSON}"
  fi
fi

# generate a new key pair to be used by tests
echo "Generating a temporary key for the test..."
TEST_KEY_NAME=$(ssh_key_name_for_job)
ssh_key_create $TEST_KEY_NAME
# add it to the mix
export KEYS=$TEST_KEY_NAME,$KEYS

# run the main test
./$TEST

# capture the main script error code
errorCode=$?
echo "<<< Test exited with error code $errorCode"

# run the cleanup in all cases
if [ -z "$TEARDOWN" ]; then
  echo "<<< No TEARDOWN script specified"
else
  echo "<<< Running teardown $TEARDOWN"
  ./$TEARDOWN
fi

# Delete the temporary SSH key last
TEST_KEY_NAME=$(ssh_key_name_for_job)
ssh_key_delete_if_exists $TEST_KEY_NAME

# raise error so this step fails
if [ $errorCode -ne 0 ]; then
  exit $errorCode
else
  exit 0
fi
