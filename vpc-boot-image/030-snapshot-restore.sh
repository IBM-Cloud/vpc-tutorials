#!/bin/bash
set -e
set -o pipefail

success=false
trap check_finish EXIT
check_finish() {
  if [ $success = true ]; then
    echo '>>>' success
  else
    echo "FAILED"
  fi
}

this_dir=$(dirname "$0")
source $this_dir/shared.sh

vpc_id=$(read_terraform_variable vpc_id)
subnet_id=$(read_terraform_variable subnet_id)
resource_group_id=$(read_terraform_variable resource_group_id)
key=$(read_terraform_variable key)
profile=$(read_terraform_variable profile)

ibmcloud is snapshots

$this_dir/ssrestore.sh $RESTORE_NAME $RESTORE_NAME $vpc_id $subnet_id $key $profile

success=true
