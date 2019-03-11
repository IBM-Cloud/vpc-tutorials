#!/bin/bash
#
# configuration used by other scripts
#

# All resources will be prefixed by this basename
BASENAME=vpns2s

# name of the ssh key that will be used for instance creation - create this in advance in the cloud
KEYNAME=yourKeyName
KEYNAME=pfq; #todo

# set this to the resource group
RESOURCE_GROUP_NAME=yourResourceGroup
RESOURCE_GROUP_NAME=pquiring@us.ibm.com; # todo

# a floating IP for ssh access will be attached to the vsis created. You can further firewall access to these
# vsis with firewall security group settings from a specific CIDR block that covers the computer executing these scripts
# 0.0.0.0/0 allows access from anywhere and may be appropriate for this tutorial.
ONPREM_SSH_CIDR=0.0.0.0/0

# not very secure.  This is the key that needs to be shared between the two vpn gateways
PRESHARED_KEY="PRESHARED_KEY_KEEP_SECRET"

# zones here are some examples
ZONE_LEFT=eu-de-1
ZONE_RIGHT=eu-de-2
ZONE_LEFT=us-south-1
ZONE_RIGHT=us-south-2
