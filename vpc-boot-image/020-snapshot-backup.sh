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

instance_id=$(read_terraform_variable instance_id)

$this_dir/ssbackup.sh $RESTORE_NAME $instance_id

success=true
