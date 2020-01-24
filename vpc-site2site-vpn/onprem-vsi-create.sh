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


# Split string of SSH key names up, look up their IDs
# and pass the IDs back as single, comma-delimited string
function SSHKeynames2IDs {
    SSHKeys=$(ibmcloud sl call-api SoftLayer_Account getSshKeys  --mask label,id)
    keynames=$1
    keys=()
    while [ "$keynames" ] ;do
        iter=${keynames%%,*}
        keys+=($(echo $SSHKeys | jq -r '.[] | select (.label=="'$iter'") | ["--key ",.id|tostring] | add '))
        [ "$keynames" = "$iter" ] && \
        keynames='' || \
        keynames="${keynames#*,}"
    done
    printf -v res_keys "%s " "${keys[@]}"
    echo "$res_keys"
}



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

SSHKeys=$(SSHKeynames2IDs $SSHKEYNAME_CLASSIC)

echo "Going to create VSI with name ${BASENAME}-onprem-vsi in domain solution-tutorial.cloud.ibm"
ONPREM_VSI=$(ibmcloud sl vs create -H ${BASENAME}-onprem-vsi -D solution-tutorial.cloud.ibm -c 1 -m 1024 -n 100 -o Ubuntu_latest -d ${DATACENTER_ONPREM} ${SSHKeys} --force)

ONPREM_VSI_ID=$(echo "${ONPREM_VSI}" | grep "^ID" | awk {'print $2'})

echo "New machine has ID ${ONPREM_VSI_ID}, now waiting for it to become available."

until ibmcloud sl call-api SoftLayer_Virtual_Guest getPowerState --init ${ONPREM_VSI_ID} | jq -c --exit-status 'select (.keyName=="RUNNING" and .name=="Running")' >/dev/null
do 
    echo -n "."
    sleep 10
done
echo ""

# Obtain the IP address (primary IP address)
VSI_ONPREM_IP=$(ibmcloud sl call-api SoftLayer_Virtual_Guest getObject --init ${ONPREM_VSI_ID} | jq -r '.primaryIpAddress')
# Compose the onprem CIDR out of the base network ID and the CIDR
ONPREM_CIDR=$(ibmcloud sl call-api SoftLayer_Virtual_Guest getNetworkVlans --init ${ONPREM_VSI_ID} --mask subnets | jq -r '.[] | select (.subnets[0].addressSpace=="PRIVATE") | .subnets[] | select (.subnetType=="ADDITIONAL_PRIMARY") | [.networkIdentifier,"/", .cidr|tostring] | add')
echo "ONPREM_CIDR=${ONPREM_CIDR}"
echo "VSI_ONPREM_IP=${VSI_ONPREM_IP}"

# include data generated from the vpc-site2site-vpn-baseline-create.sh
. $(dirname "$0")/network_config.sh

# Concatenate the info to the network configuration file
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
CLOUD_CIDR=${CLOUD_CIDR}
VSI_CLOUD_IP=${VSI_CLOUD_IP}
SUB_CLOUD_NAME=${SUB_CLOUD_NAME}

ONPREM_CIDR=${ONPREM_CIDR}
VSI_ONPREM_IP=${VSI_ONPREM_IP}

BASTION_IP_ADDRESS=${BASTION_IP_ADDRESS}

# Use this command to access the cloud VSI with the bastion VSI as jump host:
# ssh -J root@${BASTION_IP_ADDRESS} root@${VSI_CLOUD_IP}
EOF

echo network_config.sh:
cat $(dirname "$0")/network_config.sh
