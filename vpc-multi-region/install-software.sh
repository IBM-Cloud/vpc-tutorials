#!/bin/bash
set +H
export DEBIAN_FRONTEND=noninteractive

locale-gen en_US.UTF-8

export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8
export LC_ALL=en_US.UTF-8

apt-get update

#source ~/.bashrc
# Update and install Nginx web server
echo "Installing nginx web server"
apt-get install nginx -y

ufw --force enable

ufw allow 'Nginx Full'

if [[ -z "$1" ]]; then
  echo "Provide the zone and region name"
elif [[ -n "$1" ]]; then
  echo "<!DOCTYPE html><body><h1>Hello, You are running Nginx server in $1</h1></body></html>" > /var/www/html/index.nginx-debian.html
fi

systemctl restart nginx
echo "nginx server restarted"
