#!/bin/bash
indexhtml=/usr/share/httpd/noindex/index.html

# wait for the cloud-init boot process to complete
until [ -f /$indexhtml ]; do
  date
  sleep 1
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