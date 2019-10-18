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

ImageName=$(ubuntu1804)
ImageId=$(ibmcloud is images --json | jq -r '.[] | select (.name=="'${ImageName}'") | .id')
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
    echo "VPC ID: $VPCID"
    vpcResourceAvailable vpcs $BASENAME
    VPCNAME=$BASENAME
else
    echo "Reusing VPC $REUSE_VPC"
    VPCID=$(ibmcloud is vpcs --json | jq -r '.[] | select (.name=="'${REUSE_VPC}'") | .id')
    echo "VPC ID: $VPCID"
    VPCNAME=$REUSE_VPC
fi

# Create a bastion
#
# set up few variables
BASTION_SSHKEY=$SSHKey
BASTION_IMAGE=$ImageId
BASTION_ZONE=$ZONE_BASTION
# include file to create the bastion resources
. $(dirname "$0")/../scripts/bastion-create.sh


# Create Public Gateways if not available
vpcCreatePublicGateways $VPCNAME
CLOUD_PUBGWID=$( vpcPublicGatewayIDbyZone $VPCNAME $ZONE_CLOUD )
echo "CLOUD_PUBGWID: ${CLOUD_PUBGWID}"

# Create Subnet
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

vpcResourceAvailable subnets ${SUB_CLOUD_NAME}

if ! SG=$(ibmcloud is security-group-create ${BASENAME}-sg $VPCID --json)
then
    code=$?
    echo ">>> ibmcloud is security-group-create ${BASENAME}-sg $VPCID --json"
    echo "${SG}"
    exit $code
fi
SG_ID=$(echo "$SG" | jq -r '.id')
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
echo "Creating VSI"
if ! VSI_CLOUD=$(ibmcloud is instance-create ${BASENAME}-cloud-vsi $VPCID $ZONE_CLOUD $(instance_profile) $SUB_CLOUD_ID --image-id $ImageId --key-ids $SSHKey --security-group-ids $SG_CLOUD_ID,$SGMAINT --json)
then
    code=$?
    echo ">>> ibmcloud is instance-create ${BASENAME}-cloud-vsi $VPCID $ZONE_CLOUD $(instance_profile) $SUB_CLOUD_ID --image-id $ImageId --key-ids $SSHKey --security-group-ids $SG_CLOUD_ID,$SGMAINT --json"
    echo "${VSI_CLOUD}"
    exit $code
fi

VSI_CLOUD_NIC_ID=$(echo "$VSI_CLOUD" | jq -r '.primary_network_interface.id')
VSI_CLOUD_NIC_IP=$(echo "$VSI_CLOUD" | jq -r '.primary_network_interface.primary_ipv4_address')

vpcResourceRunning instances ${BASENAME}-cloud-vsi

# CLOUD side access through bastion and internal IP address only or through VPN
VSI_CLOUD_IP=$VSI_CLOUD_NIC_IP

cat > $(dirname "$0")/network_config.sh << EOF
#!/bin/bash
# The following will be used by the strongSwan initialize script:
PRESHARED_KEY=${PRESHARED_KEY}
CLOUD_CIDR=${SUB_CLOUD_CIDR}
VSI_CLOUD_IP=${VSI_CLOUD_IP}
SUB_CLOUD_NAME=${SUB_CLOUD_NAME}

BASTION_IP_ADDRESS=${BASTION_IP_ADDRESS}
EOF

echo network_config.sh:
cat $(dirname "$0")/network_config.sh
