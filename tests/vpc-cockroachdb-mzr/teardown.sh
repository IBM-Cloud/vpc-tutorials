#!/bin/bash

# include common functions
. $(dirname "$0")/../../scripts/common.sh

# remove the key created for the test
export TEST_KEY_NAME="automated-tests-${JOB_ID}"
export TEST_KEY_ID=$(SSHKeynames2UUIDs $TEST_KEY_NAME)
ibmcloud is key-delete $TEST_KEY_ID --force

./delete.sh --template=./vpc-cockroachdb-mzr/vpc-cockroachdb-mzr.test.json --config=./vpc-cockroachdb-mzr/test.json

