#!/bin/bash
#set -ex

# Script to delete the simulated on-prem virtual server
# Usage: 
#
# (C) 2019 IBM
#
# Written by Henrik Loeser, hloeser@de.ibm.com

# Exit on errors
set -e
set -o pipefail

ONPREM_VSI_ID=$(ibmcloud sl vs list -c 1 -H ${BASENAME}-onprem-vsi -D solution-tutorial.cloud.ibm --column id --column hostname | grep onprem | awk {'print $1'})

echo "Going to cancel VSI with id ${ONPREM_VSI_ID}"

ibmcloud sl vs cancel ${ONPREM_VSI_ID} -f