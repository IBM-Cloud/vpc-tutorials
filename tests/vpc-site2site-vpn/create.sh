#!/bin/bash
set -e
set -o pipefail

this_dir=$(dirname "$0")
source $this_dir/../tests_common.sh

# create the VPC that will be reused by the following scripts
ibmcloud is vpc-create $TEST_VPC_NAME
export REUSE_VPC=$TEST_VPC_NAME

ZONE=$(ibmcloud is zones --json | jq -r .[].name | sort | head -n 1)
echo "Region is $REGION, zone is $ZONE"

# generate a classic infrastructure SSH key for the test
export TEST_KEY_NAME=$(ssh_key_name_for_job)
ibmcloud sl security sshkey-add $TEST_KEY_NAME -f $HOME/.ssh/id_rsa.pub --note "created by automated tests, will be deleted"

export BASENAME="at${JOB_ID}"
export SSHKEYNAME=$KEYS
export SSHKEYNAME_CLASSIC=$TEST_KEY_NAME
export RESOURCE_GROUP_NAME=$RESOURCE_GROUP
export ONPREM_SSH_CIDR=0.0.0.0/0
export PRESHARED_KEY="20_PRESHARED_KEY_KEEP_SECRET_19_$JOB_ID"
export DATACENTER_ONPREM=$DATACENTER
export ZONE_CLOUD=$ZONE
export ZONE_BASTION=$ZONE

env | sort

# the cloud side
export CONFIG_FILE=none
./vpc-site2site-vpn/vpc-site2site-vpn-baseline-create.sh

# the onprem side
./vpc-site2site-vpn/onprem-vsi-create.sh

# remove the onprem side at the end in any case
remove_onprem_vsi() {
  ./vpc-site2site-vpn/onprem-vsi-remove.sh
}
trap remove_onprem_vsi EXIT

# the link between the two worlds
./vpc-site2site-vpn/vpc-vpn-create.sh

# load the VPN config
. ./vpc-site2site-vpn/network_config.sh

# ssh into the instance
SSH_TMP_INSECURE_CONFIG=/tmp/insecure_config_file
cat > $SSH_TMP_INSECURE_CONFIG <<EOF
Host *
  StrictHostKeyChecking no
  UserKnownHostsFile=/dev/null
  LogLevel=quiet
EOF
scp -F $SSH_TMP_INSECURE_CONFIG ./vpc-site2site-vpn/network_config.sh ./vpc-site2site-vpn/strongswan.bash root@$VSI_ONPREM_IP:
ssh -F $SSH_TMP_INSECURE_CONFIG root@$VSI_ONPREM_IP ./strongswan.bash
