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


(
  cd terraform
  cat > terraform.tfvars <<EOF
    ibmcloud_api_key="$IBMCLOUD_API_KEY"
    prefix="$PREFIX"
    resource_group_name="$RESOURCE_GROUP_NAME"
    region="$REGION"
    vpc_ssh_key_name="$VPC_SSH_KEY_NAME"
EOF
  terraform init
  terraform apply -auto-approve
)

# wait for instance to finish the cloud init process
floating_ip=$(read_terraform_variable floating_ip)
ssh_it $floating_ip <<SSH
  set -ex
  cloud-init status --wait
SSH
cat <<< "$ssh_it_out_and_err"
success=true
