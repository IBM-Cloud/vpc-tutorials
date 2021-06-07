#!/bin/bash

# disable the auto update
systemctl stop apt-daily.service
systemctl kill --kill-who=all apt-daily.service

# wait until `apt-get updated` has been killed
while ! (systemctl list-units --all apt-daily.service | egrep -q '(dead|failed)')
do
  sleep 1;
done

apt-get update
apt-get install -y nginx

current_time=$(date "+%Y.%m.%d-%H.%M.%S.%N")
echo "Current Time : $current_time"

echo "I'm a new server created on ${current_time}" > /var/www/html/index.html
service nginx start

