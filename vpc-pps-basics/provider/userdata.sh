#!/bin/bash
yum install -y epel-release
yum install -y bind-utils nc telnet siege nginx

rm -f /usr/share/nginx/html/index.html
echo "Hello world from `hostname`" > /usr/share/nginx/html/index.html
chmod go+r /usr/share/nginx/html/index.html

systemctl start nginx
