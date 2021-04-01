#!/bin/bash

# Script used to simulate an application writing to a directory.
#
# This script will create files in a directory, sleep for 60 seconds and update the same files.  
# You can check the timestamp of the files to confirm an update is made very 60 seconds or so.
#
# (C) 2021 IBM
#
# Written by Dimitri Prosper, dimitri_prosper@us.ibm.com
#

loop_counter=0
while [ true ]
do
    for file in {0..249}
    do
        echo hello-world-$loop_counter at $(date +%Y%m%d_%H%M%S) >> "/data0/$file.txt"
    done
    loop_counter=$((loop_counter+1))
    sleep 60
done