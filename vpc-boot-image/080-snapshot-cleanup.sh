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

id_for_is_command_does_not_exist() {
  local instance_id=$1
  local is_command=$2
  if ibmcloud is $is_command --output json | jq -e '.[]|select(.id=="'$instance_id'")' > /dev/null ; then
    false
  else
    true
  fi
}

instance_json=$(ibmcloud is instances --output json | jq '.[]|select(.name=="'$RESTORE_NAME'")' 2>/dev/null)
instance_id=$(jq -r .id <<< "$instance_json")
if [ "x$instance_id" = x ]; then
  echo no instance with name $RESTORE_NAME exists
else
  ibmcloud is instance-delete --force $instance_id
   echo waiting for instance $instance_id to be deleted
  wait_for_command "id_for_is_command_does_not_exist $instance_id instances"
fi

floating_ip_id=$(ibmcloud is floating-ips --output json | jq -r '.[]|select(.name|test("'$RESTORE_NAME'"))|.id' 2>/dev/null)
if [ "x$floating_ip_id" = x ]; then
  echo no floating-ip with name $RESTORE_NAME exists
else
  ibmcloud is floating-ip-release --force $floating_ip_id
   echo waiting for floating-ip $floating_ip_id to be deleted
  wait_for_command "id_for_is_command_does_not_exist $floating_ip_id floating-ips"
fi

volume_ids=$(ibmcloud is volumes --output json | jq -r '.[]|select(.name|test("'$RESTORE_NAME'-[0-9]"))|.id' 2>/dev/null)
if [ "x$volume_ids" = x ] ; then
  echo no volume_ids with name $RESTORE_NAME exists
else
  ibmcloud is volume-delete --force $volume_ids
  for volume_id in $volume_ids; do
    echo waiting for volume $volume_id to be deleted
    wait_for_command "id_for_is_command_does_not_exist $volume_id volumes"
  done
fi

snapshot_ids=$(ibmcloud is snapshots --output json | jq -r '.[]|select(.name|test("'$RESTORE_NAME'-"))|.id' 2>/dev/null)
if [ "x$snapshot_ids" = x ] ; then
  echo no snapshot_ids with name $RESTORE_NAME exists
else
  ibmcloud is snapshot-delete --force $snapshot_ids
  for snapshot_id in $snapshot_ids; do
    echo waiting for snapshot $snapshot_id to be deleted
    wait_for_command "id_for_is_command_does_not_exist $snapshot_id snapshots"
  done
fi

success=true
