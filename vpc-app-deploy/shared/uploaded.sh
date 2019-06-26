#!/bin/bash

# centos and apache2
#indexhtml=/var/www/html/index.html
indexhtml=/var/www/html/index.nginx-debian.html
# httpd installation has this file so use it
# testupload=/usr/share/httpd/noindex/css/bootstrap.min.css

# nginx does not have a second pre existing file, so create one
testupload=/var/www/html/testupload.html

# wait for the cloud-init process that happens at boot to complete
until [ -f $indexhtml ]; do
  date
  sleep 10
done

# initial value
cat > $testupload <<EOF
hi
EOF