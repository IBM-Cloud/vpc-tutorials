#!/bin/bash
set -e
set -o pipefail
set -x
this_dir=$(dirname "$0")
source $this_dir/../tests_common.sh

install_pytest() {
  apk add python3
  python3 --version
  apk add py3-pip
  pip3 --version
  pip3 install pytest
  pytest --version
  pip3 install -r test/requirements.txt
}

cd vpc-site2site-vpn
install_pytest
export TF_IN_AUTOMATION=true
export IC_API_KEY=$API_KEY
export TF_VAR_prefix=at$JOB_ID
export TF_VAR_ssh_key_name=$(ssh_key_name_for_job)
export TF_VAR_resource_group_name=$RESOURCE_GROUP

ZONE_NUMBER=1
echo "Region is $REGION, zone is $ZONE_NUMBER"
export TF_VAR_region=$REGION
export TF_VAR_zone_number=$ZONE_NUMBER

rm -rf .terraform terraform.tfstate	terraform.tfstate.backup
terraform init
terraform apply -auto-approve -no-color
# transit gateway endpoint IP addresses may still be 0.0.0.0 in the terraform.tfstate file after the first apply
terraform apply -auto-approve -no-color
pytest -v -s
terraform destroy -auto-approve -no-color
