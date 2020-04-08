#!/bin/bash
set -x
apt-get update
apt-get install -y nginx
indexhtml=/var/www/html/index.html

# Demonstrate the availability of internet repositories.  If www.python.org is availble then other software internet software like
# npm, pip, docker, ...  if isolated only the software from the ibm mirrors can be accessed
if curl -o /tmp/x -m 3 https://www.python.org/downloads/release/python-373/; then
    echo INTERNET > $indexhtml
else
    echo ISOLATED > $indexhtml
fi