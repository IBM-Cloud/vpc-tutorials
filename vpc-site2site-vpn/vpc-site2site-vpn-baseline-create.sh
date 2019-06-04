#!/bin/bash
#set -ex

# Script to deploy VPC resources for an IBM Cloud solution tutorial
#
# (C) 2019 IBM
#
# Written by Henrik Loeser, hloeser@de.ibm.com

# Exit on errors
set -e
set -o pipefail

# include configuration
if [ -z "$CONFIG_FILE" ]; then
    echo "using config.sh for configuration"
    . $(dirname "$0")/config.sh
else    
    if [ "$CONFIG_FILE" = "none" ]; then
        echo "won't read any configuration file"
    else
        echo "using $CONFIG_FILE for configuration"
        . $(dirname "$0")/${CONFIG_FILE}
    fi
fi

# include common functions
. $(dirname "$0")/../scripts/common.sh

UbuntuImage=$(ibmcloud is images --json | jq -r '.[] | select (.name=="ubuntu-18.04-amd64") | .id')
SSHKey=$(SSHKeynames2UUIDs $SSHKEYNAME)

# check if to reuse existing VPC
if [ -z "$REUSE_VPC" ]; then
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
    VPCNAME=$BASENAME
else
    echo "Reusing VPC $REUSE_VPC"
    VPCID=$(ibmcloud is vpcs --json | jq -r '.[] | select (.name=="'${REUSE_VPC}'") | .id')
    echo "$VPCID"
    VPCNAME=$REUSE_VPC
fi

# Create a bastion
#
# set up few variables
BASTION_SSHKEY=$SSHKey
#BASTION_IMAGE=$UbuntuImage
BASTION_ZONE=$ZONE_BASTION
# include file to create the bastion resources
. $(dirname "$0")/../scripts/bastion-create.sh


# Create Public Gateways if not available
vpcCreatePublicGateways $VPCNAME
CLOUD_PUBGWID=$( vpcPublicGatewayIDbyZone $VPCNAME $ZONE_CLOUD )
echo "CLOUD_PUBGWID: ${CLOUD_PUBGWID}"

# Create Subnets
SUB_ONPREM_NAME=${BASENAME}-onprem-subnet
if ! SUB_ONPREM=$(ibmcloud is subnet-create $SUB_ONPREM_NAME $VPCID $ZONE_ONPREM --ipv4-address-count 256 --json)
then
    code=$?
    echo ">>> ibmcloud is subnet-create $SUB_ONPREM_NAME $VPCID $ZONE_ONPREM --ipv4-address-count 256 --json"
    echo "${SUB_ONPREM}"
    exit $code
fi
SUB_ONPREM_ID=$(echo "$SUB_ONPREM" | jq -r '.id')
SUB_ONPREM_CIDR=$(echo "$SUB_ONPREM" | jq -r '.ipv4_cidr_block')

SUB_CLOUD_NAME=${BASENAME}-cloud-subnet
if ! SUB_CLOUD=$(ibmcloud is subnet-create $SUB_CLOUD_NAME $VPCID $ZONE_CLOUD  --ipv4-address-count 256 --public-gateway-id $CLOUD_PUBGWID --json)
then
    code=$?
    echo ">>> ibmcloud is subnet-create $SUB_CLOUD_NAME $VPCID $ZONE_CLOUD  --ipv4-address-count 256 --public-gateway-id $CLOUD_PUBGWID --json"
    echo "${SUB_CLOUD}"
    exit $code
fi
SUB_CLOUD_ID=$(echo "$SUB_CLOUD" | jq -r '.id')
SUB_CLOUD_CIDR=$(echo "$SUB_CLOUD" | jq -r '.ipv4_cidr_block')

vpcResourceAvailable subnets ${SUB_ONPREM_NAME}
vpcResourceAvailable subnets ${SUB_CLOUD_NAME}

if ! SG=$(ibmcloud is security-group-create ${BASENAME}-sg $VPCID --json)
then
    code=$?
    echo ">>> ibmcloud is security-group-create ${BASENAME}-sg $VPCID --json"
    echo "${SG}"
    exit $code
fi
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
if ! VSI_ONPREM=$(ibmcloud is instance-create ${BASENAME}-onprem-vsi $VPCID $ZONE_ONPREM c-2x4 $SUB_ONPREM_ID --image-id $UbuntuImage --key-ids $SSHKey --security-group-ids $SG_ONPREM_ID  --json)
then
    code=$?
    echo ">>> ibmcloud is instance-create ${BASENAME}-onprem-vsi $VPCID $ZONE_ONPREM c-2x4 $SUB_ONPREM_ID --image-id $UbuntuImage --key-ids $SSHKey --security-group-ids $SG_ONPREM_ID  --json"
    echo "${VSI_ONPREM}"
    exit $code
fi
if ! VSI_CLOUD=$(ibmcloud is instance-create ${BASENAME}-cloud-vsi $VPCID $ZONE_CLOUD c-2x4 $SUB_CLOUD_ID --image-id $UbuntuImage --key-ids $SSHKey --security-group-ids $SG_CLOUD_ID,$SGMAINT --json)
then
    code=$?
    echo ">>> ibmcloud is instance-create ${BASENAME}-cloud-vsi $VPCID $ZONE_CLOUD c-2x4 $SUB_CLOUD_ID --image-id $UbuntuImage --key-ids $SSHKey --security-group-ids $SG_CLOUD_ID,$SGMAINT --json"
    echo "${VSI_CLOUD}"
    exit $code
fi

VSI_ONPREM_NIC_ID=$(echo "$VSI_ONPREM" | jq -r '.primary_network_interface.id')
VSI_CLOUD_NIC_ID=$(echo "$VSI_CLOUD" | jq -r '.primary_network_interface.id')
VSI_ONPREM_NIC_IP=$(echo "$VSI_ONPREM" | jq -r '.primary_network_interface.primary_ipv4_address')
VSI_CLOUD_NIC_IP=$(echo "$VSI_CLOUD" | jq -r '.primary_network_interface.primary_ipv4_address')

vpcResourceRunning instances ${BASENAME}-onprem-vsi
vpcResourceRunning instances ${BASENAME}-cloud-vsi

# Floating IP for onprem VSI
if ! VSI_ONPREM_IP_JSON=$(ibmcloud is floating-ip-reserve ${BASENAME}-onprem-ip --nic-id $VSI_ONPREM_NIC_ID --json)
then
    code=$?
    echo ">>> ibmcloud is floating-ip-reserve ${BASENAME}-onprem-ip --nic-id $VSI_ONPREM_NIC_ID --json"
    echo "${VSI_ONPREM_IP_JSON}"
    exit $code
fi
VSI_ONPREM_IP=$(echo "${VSI_ONPREM_IP_JSON}" | jq -r '.address')

vpcResourceAvailable floating-ips ${BASENAME}-onprem-ip


# CLOUD side access through bastion and internal IP address only or through VPN
VSI_CLOUD_IP=$VSI_CLOUD_NIC_IP

cat > $(dirname "$0")/network_config.sh << EOF
#!/bin/bash
# Your "on-prem" strongSwan VSI public IP address: $VSI_ONPREM_IP
# Your cloud bastion IP address: $BASTION_IP_ADDRESS
# Your cloud VPC/VSI microservice private IP address: $VSI_CLOUD_IP

# if the ssh key is not the default for ssh try the -I PATH_TO_PRIVATE_KEY_FILE option
# from your machine to the onprem VSI
# ssh root@$VSI_ONPREM_IP
# from your machine to the bastion
# ssh root@$BASTION_IP_ADDRESS
# from your machine to the cloud VSI jumping through the bastion
# ssh -J root@$BASTION_IP_ADDRESS root@$VSI_CLOUD_IP
# from the bastion VSI to the cloud VSI
# ssh root@$VSI_CLOUD_IP

# When the VPN gateways are connected you will be able to ssh between them over the VPN connection:
# From your machine see if you can jump through the onprem VSI through the VPN gateway to the cloud VSI:
# ssh -J root@$VSI_ONPREM_IP root@$VSI_CLOUD_IP
# From your machine see if you can jump through the bastion to the cloud VSI through the VPN to the onprem VSI 
# ssh -J root@BASTION_IP_ADDRESS,root@$VSI_CLOUD_IP root@$VSI_ONPREM_IP
# From the bastion jump through the cloud VSI through the VPN to the onprem VSI:
# ssh -J root@$VSI_CLOUD_IP root@$VSI_ONPREM_IP

# The following will be used by the strongSwan initialize script:
PRESHARED_KEY=${PRESHARED_KEY}
CLOUD_CIDR=${SUB_CLOUD_CIDR}
VSI_CLOUD_IP=${VSI_CLOUD_IP}
SUB_CLOUD_NAME=${SUB_CLOUD_NAME}

ONPREM_CIDR=${SUB_ONPREM_CIDR}
ONPREM_IP=${VSI_ONPREM_IP}
SUB_ONPREM_NAME=${SUB_ONPREM_NAME}

BASTION_IP_ADDRESS=${BASTION_IP_ADDRESS}

# Use this command to access the cloud VSI with the bastion VSI as jump host:
# ssh -J root@${BASTION_IP_ADDRESS} root@${VSI_CLOUD_IP}
EOF
echo network_config.sh:
cat $(dirname "$0")/network_config.sh
