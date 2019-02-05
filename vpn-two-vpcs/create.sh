#!/bin/bash
set -x

if [ -z "$2" ]; then 
              echo usage: $0 zone ssh-keyname [naming-prefix]
              exit
fi

export zone=$1
export keyname=$2

if [ -z "$3" ]; then 
    export prefix=""
else
    export prefix=$3
fi    

export basename="vpc-pubpriv"
#. ./vpc-pubpriv-create.sh $zone $keyname 10.240.0.0/24 ${prefix}1
#. ./vpc-pubpriv-create.sh $zone $keyname 10.240.1.0/24 ${prefix}2

. ./create-vpns.sh ${prefix} ${prefix}0vpn-frontend-subnet ${prefix}1vpn-frontend-subnet
