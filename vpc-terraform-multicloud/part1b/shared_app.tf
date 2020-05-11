# The user_data application is shared by all of the VSIs.  It is a hello world app contained in two files
# app.js - node app
# a-app.service - systemctl service that wraps the app.js
#
# The string can be connected to a remote app by replacing the string REMOTE_IP, something like this:
# ... user_data = "${replace(local.shared_app_user_data, "REMOTE_IP", ibm_is_instance.vsi2.primary_network_interface.0.primary_ipv4_address)}"
locals {
  shared_app_user_data = <<EOS
#!/bin/sh
apt update -y
apt install nodejs -y
cat > /app.js << 'EOF'
${file("./app/app.js")}
EOF
cat > /lib/systemd/system/a-app.service << 'EOF'
${file("./app/a-app.service")}
EOF
systemctl daemon-reload
systemctl start a-app
EOS

}

