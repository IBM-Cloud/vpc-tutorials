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


ssh_it() {
  local host=$1
  ssh -T -q -o "StrictHostKeyChecking=no" root@$host
}
ssh_command() {
  local host=$1
  local command="$2"
  ssh -t -o "StrictHostKeyChecking=no" root@$host "$command"
}
ssh_wait() {
  # wait for ssh to start working
  wait_for_command "ssh -q -o StrictHostKeyChecking=no root@$1 exit"
}

cloud_init_wait() {
  # wait for cloud init to complete
  local fip=$1
  ssh_it $fip <<EOF
    cloud-init status --wait
EOF
}

fip=$(ibmcloud is floating-ips --output json | jq -r '.[]|select(.name|test("'$RESTORE_NAME'"))|.address')
ssh_wait $fip
cloud_init_wait $fip

ssh_command $fip "$(cat $this_dir/test_volume.sh)"

success=true
