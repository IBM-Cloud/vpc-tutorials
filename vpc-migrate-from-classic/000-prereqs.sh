#!/bin/bash
set -e

ibmcloud is target --gen 1
ibmcloud target -g $RESOURCE_GROUP_NAME
terraform version
ibmcloud cos config list
