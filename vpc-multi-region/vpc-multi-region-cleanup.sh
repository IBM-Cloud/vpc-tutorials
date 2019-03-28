#!/bin/bash
if [[ -z "$1" ]] && [[ -z "$2" ]]; then
    echo "usage: $0 vpc-name load-balancer-name"
    echo "Removes VPC and its related resources"
    exit
fi
export vpcname=$1
export lbname=$2

echo "Deleting CIS GLB resources...."
cd cis && ./cis-glb-cleanup.sh

echo "Deleting VPC load balancers..."
cd ../../scripts && ./load-balancer-cleanup.sh $lbname

echo "Deleting VPC resources..."
./vpc-cleanup.sh $vpcname