#!/bin/bash

# include common functions
. $(dirname "$0")/../../scripts/common.sh

# remove the key created for the test
export TEST_KEY_NAME="automated-tests-${JOB_ID}"
export TEST_KEY_ID=$(SSHKeynames2UUIDs $TEST_KEY_NAME)
ibmcloud is key-delete $TEST_KEY_ID --force

CLASSIC_SSH_KEYS=$(ibmcloud sl call-api SoftLayer_Account getSshKeys)
CLASSIC_SSH_KEY_TO_DELETE=$(echo $CLASSIC_SSH_KEYS | jq -r '.[] | select(.label=="'$TEST_KEY_NAME'") | .id')
ibmcloud sl security sshkey-remove $CLASSIC_SSH_KEY_TO_DELETE -f
