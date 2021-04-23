#!/bin/bash
set -e
set -o pipefail
this_dir=$(dirname "$0")
# source $this_dir/../scripts/common.sh
# source $this_dir/../scripts/common-cleanup-functions.sh

_WAIT_TIME=600
wait_for_command() {
  # command="$1"
  let "begin = $(date +'%s')"
  local elapsed=0
  local first_time=true
  while (( $_WAIT_TIME > $elapsed )); do
    if eval "$1"; then
      [ $first_time = false ] && echo
      return 0
    fi
    [ $first_time = true ] && echo -n retry for $_WAIT_TIME seconds: ''
    first_time=false
    sleep 10
    let "elapsed = $(date +%s) - $begin"
    echo -n $elapsed ''
  done
  echo
  return 1
}

image_id() {
  ibmcloud is images --json | jq -r '.[] | select (.name=="'$1'") | .id'
}

read_terraform_variable() {
  terraform output -raw -state $this_dir/terraform/terraform.tfstate $1
}

read_terraform_variables(){
  resource_group_id=$(read_terraform_variable resource_group_id)
  subnet_id=$(read_terraform_variable subnet_id)
  vpc_id=$(read_terraform_variable vpc_id)
  zone=$(read_terraform_variable zone)
}
names(){
  instance_name=$PREFIX-$1
  image_name=ibm-ubuntu-18-04-1-minimal-amd64-2
  image_name=ibm-ubuntu-20-04-minimal-amd64-2
  instance_profile=cx2-2x4
}

floating_ip_reserve(){
  ibmcloud is floating-ip-reserve $instance_name --nic-id $nic_id --json
}

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

bootvolume_populate() {
  ssh_command $fip "$(cat $this_dir/bootinit.sh)"
}

snapshot_name() {
  echo $PREFIX-$(date "+%Y-%m-%d-%H-%M-%S")
}

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
instance_id_exists() {
  local id=$1
  instances_json=$(ibmcloud is instances --output json)
  instance_id_exists=$(jq -e '.[]|select(.id=="'$id'")' <<< "$instances_json")
}
instance_gone() {
  ! instance_id_exists $1
}

instance_fip_create_wait() {
  # create an instance and a fip for the instance then wait for the instance to complete cloud-init
  # pass the snapshot id to boot from a snapshot otherwise use an image
  snapshot_id=$1
  key_id=$(ibmcloud is keys --output json | jq -r '.[]|select(.name=="'$VPC_SSH_KEY_NAME'")|.id')

  if [ x$snapshot_id = x ]; then
    instance_json=$(ibmcloud is instance-create $instance_name $vpc_id $zone $instance_profile $subnet_id --image-id $(image_id $image_name) --key-ids $key_id --output json)
  else
    local boot_volume_json=$(cat <<____EOF
      {
       "name":"$instance_name-boot",
       "volume":{
          "profile":{
             "name":"general-purpose"
          },
          "name":"$instance_name-boot",
          "source_snapshot":{
             "id":"$snapshot_id"
          }
       }
      }
____EOF
    )
    instance_json=$(ibmcloud is instance-create $instance_name $vpc_id $zone $instance_profile $subnet_id --boot-volume "$boot_volume_json" --key-ids $key_id --output json)
  fi

  instance_id=$(jq -r '.id' <<< "$instance_json")
  
  echo '>>>' wait for instance to move to the running state
  wait_for_command "instance_running $instance_id"
  nic_id=$(jq -r '.primary_network_interface.id' <<< "$instance_json")
  floating_ip_json=$(ibmcloud is floating-ip-reserve $instance_name --nic-id $nic_id --json)
  fip=$(jq -r .address <<< "$floating_ip_json")
  # instance json was not fully fleshed out on the create, take another look
  instance_json=$(ibmcloud is instance $instance_id --output json)
  echo '>>>' wait for instance to be done with cloud-init
  ssh_wait $fip
  cloud_init_wait $fip
}

instance_fip_delete_wait() {
  # delete instance and fip named instance_name
  for id in $(ibmcloud is floating-ips --output json | jq -r '.[]|select(.name=="'$instance_name'")|.id'); do
    ibmcloud is floating-ip-release -f $id
  done
  for id in $(ibmcloud is instances --output json | jq -r '.[]|select(.name=="'$instance_name'")|.id'); do
    ibmcloud is instance-delete -f $id
    wait_for_command "instance_gone $id"
  done
}

snapshot_ready() {
  snapshot_id=$1  
  snapshot_json=$(ibmcloud is snapshot $snapshot_id --output json)
  state=$(jq -r .lifecycle_state <<< "$snapshot_json")
  case $state in
  stable) true;;
  pending) false;;
  *) jq . <<< "$snapshot_json"; echo snapshot creation resulted in unknown state; exit 1;;
  esac
}

read_terraform_variables
if [ $1 = create ]; then
  names snapcreate
  echo '>>>' create an instance
  instance_fip_create_wait
  echo '>>>' populate the boot volume
  bootvolume_populate $fip
  volume_id=$(jq -r .boot_volume_attachment.volume.id <<< "$instance_json")
  snapshot_name=$(snapshot_name)
  echo '>>>' create the snapshot
  snapshot_json=$(ibmcloud is snapshot-create --name $snapshot_name --volume $volume_id --output json)
  snapshot_id=$(jq -r .id <<< "$snapshot_json")
  echo '>>>' wait for the snapshot to move to the stable state
  wait_for_command "snapshot_ready $snapshot_id"
  echo '>>>' delete instance
  instance_fip_delete_wait
  echo '>>>' snapshot id: $napshot_id
fi

if [ $1 = test ]; then
  names snaptest
  # newest matching snapshot
  echo '>>>' find latest snapshot
  snapshot_id=$(ibmcloud is snapshots --output json | jq -r '[.[]|select(.name|test("^'$PREFIX'"))]|sort|reverse[0].id')
  echo '>>>' create an instance from snapshot
  instance_fip_create_wait $snapshot_id
  echo '>>>' test instance
  version=$(curl -s $fip/version)
  [ $version = 1 ]
  echo '>>>' delete instance
  instance_fip_delete_wait
fi

if [ $1 = delete ]; then
  names snapcreate
  instance_fip_delete_wait
  names snaptest
  instance_fip_delete_wait
fi

