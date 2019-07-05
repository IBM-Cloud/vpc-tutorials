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

# log in
ibmcloud config --check-version=false
ibmcloud login --apikey $API_KEY -r $REGION -g $RESOURCE_GROUP

# set the default infrastructure target
ibmcloud is target --gen 1

if [ "$KEYS" ];
then
  echo "KEYS has been specified in the environment"
else
  echo "KEYS not specified in the environment, will use all existing keys"
  if KEYS_JSON=$(ibmcloud is keys --json)
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

# Delete the temporary SSH key
TEST_KEY_NAME=$(ssh_key_name_for_job)
ssh_key_delete_if_exists $TEST_KEY_NAME

# run the cleanup in all cases
if [ -z "$TEARDOWN" ]; then
  echo "<<< No TEARDOWN script specified"
else
  echo "<<< Running teardown $TEARDOWN"
  ./$TEARDOWN
fi

# raise error so this step fails
if [ $errorCode -ne 0 ]; then
  exit $errorCode
else
  exit 0
fi
