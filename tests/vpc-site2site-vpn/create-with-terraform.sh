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
# Testing, test_dns, is verifying the DNS resolution on-prem matches the endpoint gateways and this is failing
# for two different reasons.
# 1. Problem: terraform output ip_endpoint_gateway_cos was 0.0.0.0
#    ibm_is_virtual_endpoint_gateway.cos.ips[0].address
#    Fix: extra time, run terraform apply again, and the endpoint will have an address
# 2. dig from either the cloud or onprem is returning the public addresses: 166.* 
#    def test_dns():
#      for connection in (connection_ip_fip_bastion_to_ip_private_cloud, connection_ip_fip_onprem):
#        with connection() as c:
#          ret = c.run(f"/usr/bin/dig +short {global_cache.hostname_postgresql}", in_stream=False)
#>         assert global_cache.ip_endpoint_gateway_postgresql == ret.stdout.strip()
#E         AssertionError: assert '10.1.1.9' == 'icd-prod-us-...7\n166.9.90.6'
#E           + 10.1.1.9
#E           - icd-prod-us-south-db-711595.us-south.serviceendpoint.cloud.ibm.com.
#E           - 166.9.48.66
#E           - 166.9.58.127
#E           - 166.9.90.6
#      Fix: I do not know
sleep 60
terraform apply -auto-approve -no-color
pytest -v -s
terraform destroy -auto-approve -no-color
