#!/bin/bash
apt-get update
apt-get install -y nginx

current_time=$(date "+%Y.%m.%d-%H.%M.%S.%N")
echo "Current Time : $current_time"

echo "I'm a new server created on ${current_time}" > /var/www/html/index.html
service nginx start

