#!/bin/sh
set -e

#ibmcloud is instance-network-interface-floating-ip-add

inifi_create() {
  ibmcloud is instance-network-interface-floating-ip-add $INSTANCE $NIC $FLOATING_IP
}

inifi_destroy() {
  ibmcloud is instance-network-interface-floating-ip-remove --force $INSTANCE $NIC $FLOATING_IP
}

# running on my desktop it may be required to log in
if [ x$IC_API_KEY != x ]; then
  ibmcloud login --apikey $IC_API_KEY
fi

ibmcloud target -r $REGION -g $RESOURCE_GROUP_NAME

if [ $COMMAND = create ]; then
  inifi_create
fi

if [ $COMMAND = destroy ]; then
  inifi_destroy
fi