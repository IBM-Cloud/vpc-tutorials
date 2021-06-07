#!/bin/bash

set -e
this_dir=$(dirname "$0")
source $this_dir/shared.sh

usage() {
  cat <<EOF
NAME:
  ssbackup.sh
USAGE:
  ssbackup.sh SNAPSHOT_BASENAME INSTANCE_ID
  SNAPSHOT_BASENAME: initial characters of all snapshots created
  INSTANCE_ID:       ID of the instance
EOF
}

# return 0 if the snapshot is stable, 1 if pending, and fail on anything else
snapshot_ready() {
  snapshot_id=$1  
  snapshot_json=$(ibmcloud is snapshot $snapshot_id --output json)
  state=$(jq -r .lifecycle_state <<< "$snapshot_json")
  case $state in
  stable) true;;
  pending) false;;
  *) jq . <<< "$snapshot_json"; echo snapshot creation resulted in unknown state, expecting stable or pending got $state; exit 1;;
  esac
}

if [ $# != 2 ]; then
  usage
  exit 1
fi
basename=$1
instance_id=$2

instance_json=$(ibmcloud is instance $instance_id --output json)
volume_ids=$(jq -r '.volume_attachments|.[]|.volume.id' <<< "$instance_json")
boot_volume_id=$(jq -r .boot_volume_attachment.volume.id <<< "$instance_json")

echo create a snapshot for each volume

snapshot_ids=""
index=0
for volume_id in $volume_ids; do
  echo $volume_id
  if [ $volume_id = $boot_volume_id ]; then
    snapshot_name=${basename}-b
  else
    snapshot_name=${basename}-$index
  fi
  snapshot_json=$(ibmcloud is snapshot-create --name $snapshot_name --volume $volume_id --output json)
  snapshot_id=$(jq .id <<< "$snapshot_json")
  snapshot_ids="$snapshot_ids $snapshot_id"
  let index+=1
done

echo waiting for snapshots to become ready
for snapshot_id in $snapshot_ids; do
  wait_for_command "snapshot_ready $snapshot_id"
done
