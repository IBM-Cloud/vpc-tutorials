#!/bin/bash

# Script to clean up VPC resources for an IBM Cloud solution tutorial
#
# (C) 2019 IBM
#
# Written by Henrik Loeser, hloeser@de.ibm.com
set -ex
source ./config.sh
../scripts/vpc-cleanup.sh ${BASENAME} yes
