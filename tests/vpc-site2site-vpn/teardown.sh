#!/bin/bash

# include common functions
this_dir=$(dirname "$0")
source $this_dir/../tests_common.sh

# remove the classic infrastructure key created for the test
export TEST_KEY_NAME=$(ssh_key_name_for_job)
CLASSIC_SSH_KEYS=$(ibmcloud sl call-api SoftLayer_Account getSshKeys)
CLASSIC_SSH_KEY_TO_DELETE=$(echo $CLASSIC_SSH_KEYS | jq -r '.[] | select(.label=="'$TEST_KEY_NAME'") | .id')
ibmcloud sl security sshkey-remove $CLASSIC_SSH_KEY_TO_DELETE -f
