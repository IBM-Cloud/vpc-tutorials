#!/bin/bash

loop_counter=0
while [ true ]
do
    for file in {0..249}
    do
        echo hello-world-$loop_counter > "/data0/$file.txt"
    done
    loop_counter=$((loop_counter+1))
    sleep 60
done