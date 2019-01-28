#!/bin/bash

if [ -z "$1" ]; then 
    export prefix=""
else
    export prefix=$1
fi    

export basename="vpc-pubpriv"

./vpc-cleanup.sh ${prefix}${basename}