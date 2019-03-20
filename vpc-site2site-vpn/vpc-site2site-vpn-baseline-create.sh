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
BASTION_ZONE=$ZONE_BASTION
# include file to create the bastion resources
. $(dirname "$0")/../scripts/bastion-create.sh



#
SUB_ONPREM_NAME=${BASENAME}-onprem-subnet
SUB_ONPREM=$(ibmcloud is subnet-create $SUB_ONPREM_NAME $VPCID $ZONE_ONPREM --ipv4-address-count 256 --json)
SUB_ONPREM_ID=$(echo "$SUB_ONPREM" | jq -r '.id')
SUB_ONPREM_CIDR=$(echo "$SUB_ONPREM" | jq -r '.ipv4_cidr_block')

SUB_CLOUD_NAME=${BASENAME}-cloud-subnet
SUB_CLOUD=$(ibmcloud is subnet-create $SUB_CLOUD_NAME $VPCID $ZONE_CLOUD  --ipv4-address-count 256 --json)
SUB_CLOUD_ID=$(echo "$SUB_CLOUD" | jq -r '.id')
SUB_CLOUD_CIDR=$(echo "$SUB_CLOUD" | jq -r '.ipv4_cidr_block')

vpcResourceAvailable subnets ${SUB_ONPREM_NAME}
vpcResourceAvailable subnets ${SUB_CLOUD_NAME}

SG=$(ibmcloud is security-group-create ${BASENAME}-sg $VPCID --json)
SG_ID=$(echo "$SG" | jq -r '.id')
SG_ONPREM_ID=$SG_ID
SG_CLOUD_ID=$SG_ID

#ibmcloud is security-group-rule-add GROUP_ID DIRECTION PROTOCOL
echo "Creating rules"

# inbound
ibmcloud is security-group-rule-add $SG_ID inbound tcp  --remote $ONPREM_SSH_CIDR --port-min  80 --port-max  80 > /dev/null
ibmcloud is security-group-rule-add $SG_ID inbound tcp  --remote $ONPREM_SSH_CIDR --port-min 443 --port-max 443 > /dev/null
ibmcloud is security-group-rule-add $SG_ID inbound tcp  --remote $ONPREM_SSH_CIDR --port-min  22 --port-max  22 > /dev/null
ibmcloud is security-group-rule-add $SG_ID inbound icmp --remote $ONPREM_SSH_CIDR --icmp-type  8 > /dev/null
# all outbound access permitted
ibmcloud is security-group-rule-add $SG_ID outbound all > /dev/null

# App and VPN servers
echo "Creating VSIs"
VSI_ONPREM=$(ibmcloud is instance-create ${BASENAME}-onprem-vsi   $VPCID $ZONE_ONPREM c-2x4 $SUB_ONPREM_ID   1000 --image-id $UbuntuImage --key-ids $SSHKey --security-group-ids $SG_ONPREM_ID  --json)
VSI_CLOUD=$(ibmcloud is instance-create ${BASENAME}-cloud-vsi $VPCID $ZONE_CLOUD c-2x4 $SUB_CLOUD_ID 1000 --image-id $UbuntuImage --key-ids $SSHKey --security-group-ids $SG_CLOUD_ID,$SGMAINT --json)


VSI_ONPREM_NIC_ID=$(echo "$VSI_ONPREM" | jq -r '.primary_network_interface.id')
VSI_CLOUD_NIC_ID=$(echo "$VSI_CLOUD" | jq -r '.primary_network_interface.id')
VSI_ONPREM_NIC_IP=$(echo "$VSI_ONPREM" | jq -r '.primary_network_interface.primary_ipv4_address')
VSI_CLOUD_NIC_IP=$(echo "$VSI_CLOUD" | jq -r '.primary_network_interface.primary_ipv4_address')

vpcResourceRunning instances ${BASENAME}-ONPREM-vsi
vpcResourceRunning instances ${BASENAME}-CLOUD-vsi

# Floating IP for frontend
VSI_ONPREM_IP=$(ibmcloud is floating-ip-reserve ${BASENAME}-onprem-ip --nic-id $VSI_ONPREM_NIC_ID --json | jq -r '.address')
#VSI_CLOUD_IP=$(ibmcloud is floating-ip-reserve ${BASENAME}-cloud-ip --nic-id $VSI_CLOUD_NIC_ID --json | jq -r '.address')
vpcResourceAvailable floating-ips ${BASENAME}-onprem-ip
#vpcResourceAvailable floating-ips ${BASENAME}-cloud-ip

# CLOUD side access through bastion and internal IP address only or through VPN
VSI_CLOUD_IP=$VSI_CLOUD_NIC_IP

cat > data.sh << EOF
#!/bin/bash
#Your onprem strongswan vsi IP address: $VSI_ONPREM_IP
#Your cloud VPC/VSI microservice IP address: $VSI_CLOUD_IP

# if the ssh key is not the default for ssh try the -I PATH_TO_PRIVATE_KEY_FILE option
# ssh root@$VSI_ONPREM_IP
# ssh root@$VSI_CLOUD_IP

# When the vpn gateways are connected you will be able to ssh between them over the vpn connection:
# ssh -J root@$VSI_ONPREM_IP root@$VSI_CLOUD_IP
# ssh -J root@$VSI_CLOUD_IP root@$VSI_ONPREM_IP

# The following will be used by the strongswan initialize script:
PRESHARED_KEY=${PRESHARED_KEY}
CLOUD_CIDR=${SUB_CLOUD_CIDR}
VSI_CLOUD_IP=${VSI_CLOUD_IP}
SUB_CLOUD_NAME=${SUB_CLOUD_NAME}

ONPREM_CIDR=${SUB_ONPREM_CIDR}
ONPREM_IP=${VSI_ONPREM_IP}
SUB_ONPREM_NAME=${SUB_ONPREM_NAME}
ME=ONPREM

BASTION_IP_ADDRESS=${BASTION_IP_ADDRESS}
EOF
echo data.sh:
cat data.sh
