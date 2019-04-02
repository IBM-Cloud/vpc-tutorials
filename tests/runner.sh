#!/bin/bash
set -x

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

# run the main test
./$TEST

# capture the main script error code
errorCode=$?

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
