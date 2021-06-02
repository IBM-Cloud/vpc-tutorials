#!/bin/bash

set -e
this_dir=$(dirname "$0")
source $this_dir/shared.sh

usage() {
  cat <<EOF
NAME:
  ssrestore.sh
USAGE:
  ssrestore.sh SNAPSHOT_NAME INSTANCE_NAME VPC SUBNET KEY PROFILE_NAME
  SNAPSHOT_NAME: initial characters of all snapshots previously created with ssbackup
  INSTANCE_NAME: initial characters of all volumes and instances created by this script
  VPC:           ID of the VPC for the instance created by this script.
  SUBNET:        ID of the subnet for the instance created by this script.
  KEY:           ID of the ssh ke for the instance created by this script.
  PROFILE_NAME:  Name of the profile for the instance created by this script.
EOF
}

if [ $# != 6 ]; then
  usage
  exit 1
fi

instance_running() {
  local instance_id=$1  
  local instance_json=$(ibmcloud is instance $instance_id --output json)
  local status=$(jq -r .status <<< "$instance_json")
  case $status in
  running) true;;
  starting) false;;
  *) jq . <<< "$instance_json"; echo instance creation resulted in unknown status: $status; exit 1;;
  esac
}

basename=$1
instance_name=$2
vpc_id=$3
subnet_id=$4
key_id=$5
instance_profile=$6

snapshots_json=$(ibmcloud is snapshots --output json)
snapshot_ids=$(jq -r 'sort_by(.name)|.[]|select(.name|test("'$basename'-[0-9]+"))|.id' <<< "$snapshots_json")
boot_snapshot_id=$(jq -r 'sort_by(.name)|.[]|select(.name|test("'$basename'-b"))|.id' <<< "$snapshots_json")
name="${instance_name}-b"
boot_volume_json=$(cat <<EOF
  {
   "name":"$name",
   "volume":{
      "profile":{
         "name":"general-purpose"
      },
      "name":"$name",
      "source_snapshot":{
         "id":"$boot_snapshot_id"
      }
   }
  }
EOF
)

index=1
data_volumes_json='[]'
for snapshot_id in $snapshot_ids; do
  name="${instance_name}-$index"
  echo 0
  data_volume=$(cat <<__EOF
    {
     "name":"$name",
     "volume":{
        "profile":{
           "name":"general-purpose"
        },
        "name":"$name",
        "source_snapshot":{
           "id":"$snapshot_id"
        }
     }
    }
__EOF
    )
    echo 1
    jq . <<< "$data_volume"
    data_volumes_json=$(jq '[ .[], '"$data_volume"']' <<< "$data_volumes_json")
    echo index $index
  let index+=1
done
echo "$boot_volume_json"
jq . <<< "$boot_volume_json"
jq . <<< "$data_volumes_json"

subnet_json=$(ibmcloud is subnet --output json $subnet_id)
zone=$(jq -r .zone.name <<< "$subnet_json")

instance_json=$(ibmcloud is instance-create $instance_name $vpc_id $zone $instance_profile $subnet_id --boot-volume "$boot_volume_json" --volume-attach "$data_volumes_json" --key-ids $key_id --output json)

instance_id=$(jq -r .id <<< "$instance_json")
wait_for_command "instance_running $instance_id"

nic_id=$(jq -r '.primary_network_interface.id' <<< "$instance_json")
ibmcloud is floating-ip-reserve $instance_name --nic-id $nic_id --json
