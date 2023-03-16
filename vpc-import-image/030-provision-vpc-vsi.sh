#!/bin/bash
set -e
set -o pipefail

source $(dirname "$0")/trap_begin.sh

my_dir=$(dirname "$0")

ZONE=$(ibmcloud is zones --output json | jq -r .[].name | sort | head -1)
echo "Region is $REGION, zone is $ZONE"

# create VSIs
image_names='['
for IMAGE_NAME in $IMAGE_VARIABLES; do
  image_names="$image_names "'"'"$IMAGE_NAME"'",'
done
image_names="$image_names ]"
(
  set -e
  cd $my_dir/create-vpc-vsi
  cat > terraform.tfvars <<EOF
vsi_image_names=$image_names
ibmcloud_api_key="$IBMCLOUD_API_KEY"
ssh_key_name="$VPC_SSH_KEY_NAME"
resource_group_name="$RESOURCE_GROUP_NAME"
prefix="$PREFIX"
subnet_zone="$ZONE"
region="$REGION"
EOF
  terraform init
  terraform apply --auto-approve
)

VPC_VSI_IP_ADDRESSES=$(cd $my_dir/create-vpc-vsi && terraform output -json VPC_VSI_IP_ADDRESSES)

# not testing currently, need to investigate a better way to provision a known server on any linux distro
if false; then
name_fip_list=$(jq -r 'to_entries | map(.key + " " + (.value | tostring)) | .[]' <<<"$VPC_VSI_IP_ADDRESSES")
done=false
while [ $done = false ]; do
  done=true
  while read name fip; do
    echo $name curl $fip
    if ! curl $fip; then
      done=false
    fi
  sleep 1
  done <<< "$name_fip_list"
done
fi

source $(dirname "$0")/trap_end.sh
