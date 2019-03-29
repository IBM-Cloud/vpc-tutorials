#!/bin/bash
set -x

echo ">>> Running test $TEST"

# log in
ibmcloud login --apikey $API_KEY -r $REGION

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
