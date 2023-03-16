#!/bin/bash
set -e
set -o pipefail

my_dir=$(realpath $(dirname "$0"))
source $my_dir/trap_begin.sh

VPC_VSI_IP_ADDRESSES=$(cd $my_dir/create-vpc-vsi && terraform output -json VPC_VSI_IP_ADDRESSES)
#name_fip_list=$(jq -r 'to_entries | map(.key + " " + (.value | tostring)) | .[]' <<<"$VPC_VSI_IP_ADDRESSES")
name_fip_list=$(jq -r 'to_entries | map(.key + "|" + (.value | tostring)) | .[]' <<<"$VPC_VSI_IP_ADDRESSES")

dirs="
  /mnt
  /etc/system-release
  /etc/os-release
  /etc/default
  /etc/cloud
  /var/log/cloud-init.log
  /var/log/cloud-init-output.log
"

instance_files=$my_dir/instance-files
all_failures=$instance_files/failures
user=root
for name_fip in $name_fip_list ; do
  name=$(sed -e 's/|.*//' <<< $name_fip)
  fip=$(sed -e 's/.*|//' <<< $name_fip)
  echo $name $fip ------------------------------
  instance_dir=$instance_files/$name
  mkdir -p $instance_dir
  (
    set -e
    cd $instance_dir
    ssh root@$fip -o "StrictHostKeyChecking no" mount '-o' 'ro' /dev/vdb /mnt
    for dir in $dirs; do
      if ! scp -o "StrictHostKeyChecking no" -r $user@$fip:$dir .; then
        echo $name $dir >> $all_failures
      fi
    done
    ssh root@$fip -o "StrictHostKeyChecking no" umount /mnt
    chmod 775 mnt
  )
done

echo all failures:
cat $all_failures

source $my_dir/trap_end.sh
