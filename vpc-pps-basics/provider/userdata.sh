#!/bin/bash
yum install -y bind-utils nginx

rm -f /usr/share/nginx/html/index.html
echo "Hello world from `hostname`" > /usr/share/nginx/html/index.html
chmod go+r /usr/share/nginx/html/index.html

systemctl start nginx
