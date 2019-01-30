#!/bin/bash

# Script to clean up VPC resources for an IBM Cloud solution tutorial
#
# (C) 2019 IBM
#
# Written by Henrik Loeser, hloeser@de.ibm.com

if [ -z "$1" ]; then 
    export prefix=""
else
    export prefix=$1
fi    

export basename="vpc-pubpriv"

./vpc-cleanup.sh ${prefix}${basename}