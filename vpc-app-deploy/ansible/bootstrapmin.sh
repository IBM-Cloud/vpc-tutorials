#!/bin/bash

bootstrap=/usr/share/httpd/noindex/css/bootstrap.min.css

# wait for the cloud-init process that happens at boot to complete
until [ -f $bootstrap ]; do
  date
  sleep 1
done

# initial value
cat > $bootstrap <<EOF
hi
EOF