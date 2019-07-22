#!/bin/bash
#
# This is similar to the script that is in ../shared/install.sh
#
# indexhtml=/usr/share/httpd/noindex/index.html centos
# indexhtml=/var/www/html/index.html apache2
indexhtml=/var/www/html/index.nginx-debian.html

# wait for the cloud-init boot process to complete
until [ -f /$indexhtml ]; do
  date
  sleep 11
done

# initial value
cat > $indexhtml <<EOF
INIT
EOF

# Internet is availble then more software can be installed if isolated only the software
# from the ibm mirrors can be installed
if curl -o /tmp/x https://www.python.org/downloads/release/python-373/; then
  cat > $indexhtml <<EOF
INTERNET
EOF
else
  cat > $indexhtml <<EOF
ISOLATED
EOF
fi