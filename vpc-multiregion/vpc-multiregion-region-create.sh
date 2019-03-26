#!/bin/bash

# Script to create VPC resources for an IBM Cloud solution tutorial
#
# (C) 2019 IBM
#
# Written by Vidyasagar Machupalli

# Load up .env
set -a # automatically export all variables
source .env
set +a

# include common functions
. $(dirname "$0")/../scripts/common.sh
. $(dirname "$0")/common-load-balancer.sh

if [[ -z "$1" ]]; then
    echo "Provide a REGION name"
    elif [[ -n "$1" ]]; then
    REGION=$1
fi
echo "Setting the target region"
ibmcloud target -r $REGION

echo "Creating VPC in $REGION region"
VPC_OUT=$(ibmcloud is vpc-create $BASENAME-$REGION --resource-group-name ${RESOURCE_GROUP_NAME} --json)
if [ $? -ne 0 ]; then
    echo "Error while creating VPC:"
    echo "========================="
    echo "$VPC_OUT"
    exit
fi
VPCID=$(echo "$VPC_OUT"  | jq -r '.id')

vpcResourceAvailable vpcs $BASENAME-$REGION

export UbuntuImage=$(ibmcloud is images --json | jq -r '.[] | select (.name=="ubuntu-18.04-amd64") | .id')
export SSHKey=$(SSHKeynames2UUIDs $KEYNAME)
# Create a bastion
#
# set up few variables
BASTION_SSHKEY=$SSHKey
BASTION_IMAGE=$UbuntuImage
BASTION_ZONE=$REGION-1
BASTION_NAME=bastion-$BASTION_ZONE
# include file to create the bastion resources
. $(dirname "$0")/../scripts/bastion-create.sh


SUB_ZONE1_NAME=${BASENAME}-$REGION-1-subnet
SUB_ZONE1=$(ibmcloud is subnet-create $SUB_ZONE1_NAME $VPCID $REGION-1 --ipv4-address-count 256 --json)
SUB_ZONE1_ID=$(echo "$SUB_ZONE1" | jq -r '.id')
SUB_ZONE1_CIDR=$(echo "$SUB_ZONE1" | jq -r '.ipv4_cidr_block')

SUB_ZONE2_NAME=${BASENAME}-$REGION-2-subnet
SUB_ZONE2=$(ibmcloud is subnet-create $SUB_ZONE2_NAME $VPCID $REGION-2 --ipv4-address-count 256 --json)
SUB_ZONE2_ID=$(echo "$SUB_ZONE2" | jq -r '.id')
SUB_ZONE2_CIDR=$(echo "$SUB_ZONE2" | jq -r '.ipv4_cidr_block')

vpcResourceAvailable subnets ${SUB_ZONE1_NAME}
vpcResourceAvailable subnets ${SUB_ZONE2_NAME}

SG=$(ibmcloud is security-group-create ${BASENAME}-sg $VPCID --json)
SG_ID=$(echo "$SG" | jq -r '.id')
SG_ZONE1_ID=$SG_ID
SG_ZONE2_ID=$SG_ID

#ibmcloud is security-group-rule-add GROUP_ID DIRECTION PROTOCOL
echo "Creating rules"

# inbound
ibmcloud is security-group-rule-add $SG_ID inbound tcp  --remote "0.0.0.0/0" --port-min  80 --port-max  80 > /dev/null
ibmcloud is security-group-rule-add $SG_ID inbound tcp  --remote "0.0.0.0/0" --port-min 443 --port-max 443 > /dev/null
# all outbound access permitted
#ibmcloud is security-group-rule-add $SG_ID outbound all > /dev/null

# App and VPN servers
echo "Creating VSIs"
VSI_ZONE1=$(ibmcloud is instance-create ${BASENAME}-$REGION-zone1-vsi $VPCID $REGION-1 c-2x4 $SUB_ZONE1_ID 1000 --image-id $UbuntuImage --key-ids $SSHKey --security-group-ids $SG_ZONE1_ID,$SGMAINT  --json)
VSI_ZONE2=$(ibmcloud is instance-create ${BASENAME}-$REGION-zone2-vsi $VPCID $REGION-2 c-2x4 $SUB_ZONE2_ID 1000 --image-id $UbuntuImage --key-ids $SSHKey --security-group-ids $SG_ZONE2_ID,$SGMAINT --json)


VSI_ZONE1_NIC_ID=$(echo "$VSI_ZONE1" | jq -r '.primary_network_interface.id')
VSI_ZONE2_NIC_ID=$(echo "$VSI_ZONE2" | jq -r '.primary_network_interface.id')
VSI_ZONE1_NIC_IP=$(echo "$VSI_ZONE1" | jq -r '.primary_network_interface.primary_ipv4_address')
VSI_ZONE2_NIC_IP=$(echo "$VSI_ZONE2" | jq -r '.primary_network_interface.primary_ipv4_address')

vpcResourceRunning instances ${BASENAME}-$REGION-zone1-vsi
vpcResourceRunning instances ${BASENAME}-$REGION-zone2-vsi
echo "ZONE1 PRIVATE_IP:$VSI_ZONE1_NIC_IP"
echo "ZONE2 PRIVATE_IP:$VSI_ZONE2_NIC_IP"

# Floating IP for instance
VSI_ZONE1_IP=$(ibmcloud is floating-ip-reserve ${BASENAME}-$REGION-zone1-ip --nic-id $VSI_ZONE1_NIC_ID --json | jq -r '.address')
VSI_ZONE2_IP=$(ibmcloud is floating-ip-reserve ${BASENAME}-$REGION-zone2-ip --nic-id $VSI_ZONE2_NIC_ID --json | jq -r '.address')

vpcResourceAvailable floating-ips ${BASENAME}-$REGION-zone1-ip
vpcResourceAvailable floating-ips ${BASENAME}-$REGION-zone2-ip
echo "ZONE1 FLOATING_IP: $VSI_ZONE1_IP"
echo "ZONE2 FLOATING_IP: $VSI_ZONE2_IP"

#for IP in $BASTION_IP_ADDRESS $VSI_ZONE1_NIC_IP $VSI_ZONE2_NIC_IP
#do
#    ssh-keygen -R $IP
#    ssh-keyscan -H $IP >> ~/.ssh/known_hosts
#done

echo "Installing the required software in each instance"
ssh -J root@$BASTION_IP_ADDRESS root@$VSI_ZONE1_NIC_IP 'bash -s' < install-software.sh $REGION-zone1
ssh -J root@$BASTION_IP_ADDRESS root@$VSI_ZONE2_NIC_IP 'bash -s' < install-software.sh $REGION-zone2

echo "LOAD BALANCING..."
echo "Creating a load balancer..."

LOCAL_LB=$(ibmcloud is load-balancer-create ${BASENAME}-$REGION-lb public --subnets $SUB_ZONE1_ID --subnets $SUB_ZONE2_ID --resource-group-name ${RESOURCE_GROUP_NAME} --json)
LOCAL_LB_ID=$(echo "$LOCAL_LB" | jq -r '.id')
HOSTNAME=$(echo "$LOCAL_LB" | jq -r '.hostname')

vpcResourceActive load-balancers ${BASENAME}-$REGION-lb

#echo "LOCAL_LB_ID: $LOCAL_LB_ID"

#Backend Pool
echo "Adding a backend pool to the load balancer..."
LB_BACKEND_POOL=$(ibmcloud is load-balancer-pool-create ${BASENAME}-$REGION-lb-pool $LOCAL_LB_ID round_robin http 15 2 5 http --health-monitor-url / --json)
LB_BACKEND_POOL_ID=$(echo "$LB_BACKEND_POOL" | jq -r '.id')

#echo "LB_BACKEND_POOL_ID: $LB_BACKEND_POOL_ID"

vpcLBResourceActive load-balancer-pools ${BASENAME}-$REGION-lb-pool $LOCAL_LB_ID

LB_BACKEND_POOL_MEMBER_1_ID=$(ibmcloud is load-balancer-pool-member-create $LOCAL_LB_ID $LB_BACKEND_POOL_ID 80 $VSI_ZONE1_NIC_IP --json | jq -r '.id')
vpcLBMemberActive load-balancer-pool-members $LOCAL_LB_ID $LB_BACKEND_POOL_ID $LB_BACKEND_POOL_MEMBER_1_ID

LB_BACKEND_POOL_MEMBER_2_ID=$(ibmcloud is load-balancer-pool-member-create $LOCAL_LB_ID $LB_BACKEND_POOL_ID 80 $VSI_ZONE2_NIC_IP --json | jq -r '.id')
vpcLBMemberActive load-balancer-pool-members $LOCAL_LB_ID $LB_BACKEND_POOL_ID $LB_BACKEND_POOL_MEMBER_2_ID

#vpcResourceAvailable load-balancer-pool-members ${LB_BACKEND_POOL_MEMBER_1}
#vpcResourceAvailable load-balancer-pool-members ${LB_BACKEND_POOL_MEMBER_2}

#Frontend Listener
LB_FRONTEND_LISTENER_HTTP=$(ibmcloud is load-balancer-listener-create $LOCAL_LB_ID 80 http --default-pool $LB_BACKEND_POOL_ID --json)
LB_FRONTEND_LISTENER_HTTP_ID=$(echo "$LB_FRONTEND_LISTENER_HTTP" | jq -r '.id')
vpcLBListenerActive load-balancer-listeners $LOCAL_LB_ID $LB_FRONTEND_LISTENER_HTTP_ID

LB_FRONTEND_LISTENER_HTTPS=$(ibmcloud is load-balancer-listener-create $LOCAL_LB_ID 443 https --certificate-instance-crn $CERTIFICATE_CRN --default-pool $LB_BACKEND_POOL_ID --json)
LB_FRONTEND_LISTENER_HTTPS_ID=$(echo "$LB_FRONTEND_LISTENER_HTTPS" | jq -r '.id')
vpcLBListenerActive load-balancer-listeners $LOCAL_LB_ID $LB_FRONTEND_LISTENER_HTTPS_ID

echo "Save the HOSTNAME: $HOSTNAME"
