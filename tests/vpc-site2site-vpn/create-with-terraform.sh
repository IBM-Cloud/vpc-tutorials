#!/bin/bash
set -e
set -o pipefail

# Set up environment as described in the tutorial using the variables provided by travis:

this_dir=$(dirname "$0")
source $this_dir/../../scripts/trap_begin.sh
source $this_dir/../tests_common.sh

install_pytest() {
  apk add python3
  python3 --version
  apk add py3-pip
  pip3 install -r test/requirements.txt
  pytest --version
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

# Run the tutorial.  If debugging using the travis shim you may delete the destroy or make other changes below.
terraform init
terraform apply -auto-approve -no-color
# Testing, test_dns, is verifying the DNS resolution on-prem matches the endpoint gateways and this is failing
# 1. Problem: terraform output ip_endpoint_gateway_cos was 0.0.0.0
#    ibm_is_virtual_endpoint_gateway.cos.ips[0].address
#    Fix: extra time, run terraform apply again, and the endpoint will have an address
sleep 60
terraform apply -auto-approve -no-color
pytest -v -s
terraform destroy -auto-approve -no-color

cd ..
source $this_dir/../../scripts/trap_end.sh