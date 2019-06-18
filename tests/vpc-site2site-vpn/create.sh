#!/bin/bash
set -e
set -o pipefail
set -x

# create the VPC that will be reused by the following scripts
ibmcloud is vpc-create $TEST_VPC_NAME
export REUSE_VPC=$TEST_VPC_NAME

ZONE=$(ibmcloud is zones --json | jq -r .[].name | sort | head -n 1)
echo "Region is $REGION, zone is $ZONE"

# generate an SSH key for the test
ssh-keygen -t rsa -P "" -C "automated-tests@build" -f $HOME/.ssh/id_rsa
export TEST_KEY_NAME="automated-tests-${JOB_ID}"
ibmcloud is key-create $TEST_KEY_NAME @$HOME/.ssh/id_rsa.pub

export BASENAME="at${JOB_ID}"
export SSHKEYNAME=$KEYS,$TEST_KEY_NAME
export RESOURCE_GROUP_NAME=$RESOURCE_GROUP
export ONPREM_SSH_CIDR=0.0.0.0/0
export PRESHARED_KEY="20_PRESHARED_KEY_KEEP_SECRET_19_$JOB_ID"
export ZONE_ONPREM=$ZONE
export ZONE_CLOUD=$ZONE
export ZONE_BASTION=$ZONE

env | sort

export CONFIG_FILE=none
./vpc-site2site-vpn/vpc-site2site-vpn-baseline-create.sh
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
scp -F $SSH_TMP_INSECURE_CONFIG ./vpc-site2site-vpn/network_config.sh ./vpc-site2site-vpn/strongswan.bash root@$ONPREM_IP:
ssh -F $SSH_TMP_INSECURE_CONFIG root@$ONPREM_IP ./strongswan.bash
