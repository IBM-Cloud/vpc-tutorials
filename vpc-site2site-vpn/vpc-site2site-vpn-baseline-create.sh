#!/bin/bash
#set -ex

# Script to deploy VPC resources for an IBM Cloud solution tutorial
#
# (C) 2019 IBM
#
# Written by Henrik Loeser, hloeser@de.ibm.com

# include configuration
. $(dirname "$0")/config.sh

# include common functions
. $(dirname "$0")/../scripts/common.sh

export UbuntuImage=$(ibmcloud is images --json | jq -r '.[] | select (.name=="ubuntu-18.04-amd64") | .id')
export SSHKey=$(SSHKeynames2UUIDs $KEYNAME)

echo "Creating VPC"
VPC_OUT=$(ibmcloud is vpc-create $BASENAME --resource-group-name ${RESOURCE_GROUP_NAME} --json)
if [ $? -ne 0 ]; then
    echo "Error while creating VPC:"
    echo "========================="
    echo "$VPC_OUT"
    exit
fi
VPCID=$(echo "$VPC_OUT"  | jq -r '.id')

vpcResourceAvailable vpcs $BASENAME


# Create a bastion
#
# set up few variables
BASTION_SSHKEY=$SSHKey
#BASTION_IMAGE=$UbuntuImage
BASTION_ZONE=$ZONE_RIGHT
# include file to create the bastion resources
. $(dirname "$0")/../scripts/bastion-create.sh



#
SUB_LEFT_NAME=${BASENAME}-left-subnet
SUB_LEFT=$(ibmcloud is subnet-create $SUB_LEFT_NAME $VPCID $ZONE_LEFT --ipv4-address-count 256 --json)
SUB_LEFT_ID=$(echo "$SUB_LEFT" | jq -r '.id')
SUB_LEFT_CIDR=$(echo "$SUB_LEFT" | jq -r '.ipv4_cidr_block')

SUB_RIGHT_NAME=${BASENAME}-right-subnet
SUB_RIGHT=$(ibmcloud is subnet-create $SUB_RIGHT_NAME $VPCID $ZONE_RIGHT  --ipv4-address-count 256 --json)
SUB_RIGHT_ID=$(echo "$SUB_RIGHT" | jq -r '.id')
SUB_RIGHT_CIDR=$(echo "$SUB_RIGHT" | jq -r '.ipv4_cidr_block')

vpcResourceAvailable subnets ${SUB_LEFT_NAME}
vpcResourceAvailable subnets ${SUB_RIGHT_NAME}

SG=$(ibmcloud is security-group-create ${BASENAME}-sg $VPCID --json)
SG_ID=$(echo "$SG" | jq -r '.id')
SG_LEFT_ID=$SG_ID
SG_RIGHT_ID=$SG_ID

#ibmcloud is security-group-rule-add GROUP_ID DIRECTION PROTOCOL
echo "Creating rules"

# inbound
ibmcloud is security-group-rule-add $SG_ID inbound tcp  --remote $ONPREM_SSH_CIDR --port-min  80 --port-max  80 > /dev/null
ibmcloud is security-group-rule-add $SG_ID inbound tcp  --remote $ONPREM_SSH_CIDR --port-min 443 --port-max 443 > /dev/null
ibmcloud is security-group-rule-add $SG_ID inbound tcp  --remote $ONPREM_SSH_CIDR --port-min  22 --port-max  22 > /dev/null
ibmcloud is security-group-rule-add $SG_ID inbound icmp --remote $ONPREM_SSH_CIDR --icmp-type  8 > /dev/null
# all outbound access permitted
ibmcloud is security-group-rule-add $SG_ID outbound all > /dev/null

# App and bastion servers
echo "Creating VSIs"
VSI_LEFT=$(ibmcloud is instance-create ${BASENAME}-left-vsi   $VPCID $ZONE_LEFT c-2x4 $SUB_LEFT_ID   1000 --image-id $UbuntuImage --key-ids $SSHKey --security-group-ids $SG_LEFT_ID  --json)
VSI_RIGHT=$(ibmcloud is instance-create ${BASENAME}-right-vsi $VPCID $ZONE_RIGHT c-2x4 $SUB_RIGHT_ID 1000 --image-id $UbuntuImage --key-ids $SSHKey --security-group-ids $SG_RIGHT_ID --json)


VSI_LEFT_NIC_ID=$(echo "$VSI_LEFT" | jq -r '.primary_network_interface.id')
VSI_RIGHT_NIC_ID=$(echo "$VSI_RIGHT" | jq -r '.primary_network_interface.id')
VSI_LEFT_NIC_IP=$(echo "$VSI_LEFT" | jq -r '.primary_network_interface.primary_ipv4_address')
VSI_RIGHT_NIC_IP=$(echo "$VSI_RIGHT" | jq -r '.primary_network_interface.primary_ipv4_address')

vpcResourceRunning instances ${BASENAME}-left-vsi
vpcResourceRunning instances ${BASENAME}-right-vsi

# Floating IP for frontend
VSI_LEFT_IP=$(ibmcloud is floating-ip-reserve ${BASENAME}-left-ip --nic-id $VSI_LEFT_NIC_ID --json | jq -r '.address')
VSI_RIGHT_IP=$(ibmcloud is floating-ip-reserve ${BASENAME}-right-ip --nic-id $VSI_RIGHT_NIC_ID --json | jq -r '.address')
vpcResourceAvailable floating-ips ${BASENAME}-left-ip
vpcResourceAvailable floating-ips ${BASENAME}-right-ip

cat > data.sh << EOF
#!/bin/bash
#Your left strongswan vsi IP address: $VSI_LEFT_IP
#Your right vpc/vsi microservice IP address: $VSI_RIGHT_IP

# if the ssh key is not the default for ssh try the -I PATH_TO_PRIVATE_KEY_FILE option
# ssh root@$VSI_LEFT_IP
# ssh root@$VSI_RIGHT_IP

# When the vpn gateways are connected you will be able to ssh between them over the vpn connection:
# ssh -J root@$VSI_LEFT_IP root@$VSI_RIGHT_IP
# ssh -J root@$VSI_RIGHT_IP root@$VSI_LEFT_IP

# The following will be used by the strongswan initialize script:
PRESHARED_KEY=${PRESHARED_KEY}
RIGHT_CIDR=${SUB_RIGHT_CIDR}
RIGHT_IP=VPCVPNIP
SUB_RIGHT_NAME=${SUB_RIGHT_NAME}

LEFT_CIDR=${SUB_LEFT_CIDR}
LEFT_IP=${VSI_LEFT_IP}
SUB_LEFT_NAME=${SUB_LEFT_NAME}
ME=LEFT

BASTION_IP_ADDRESS=${BASTION_IP_ADDRESS}
EOF
echo data.sh:
cat data.sh
