provider ibm {
  region           = "${var.ibm_region}"
  ibmcloud_api_key = "${var.ibmcloud_api_key}"
  generation       = 1                         # vpc on classic
}

data "ibm_resource_group" "group" {
  name = "${var.resource_group_name}"
}

resource ibm_is_vpc "vpc" {
  name           = "${var.basename}"
  resource_group = "${data.ibm_resource_group.group.id}"
}

resource ibm_is_security_group "sg1" {
  name           = "${var.basename}-sg1"
  vpc            = "${ibm_is_vpc.vpc.id}"
  resource_group = "${data.ibm_resource_group.group.id}"
}

# Part 1B delete this
# allow ssh access to this instance from anywhere on the planet
resource "ibm_is_security_group_rule" "ingress_ssh_all" {
  group     = "${ibm_is_security_group.sg1.id}"
  direction = "inbound"
  remote    = "0.0.0.0/0"                       # TOO OPEN for production

  tcp = {
    port_min = 22
    port_max = 22
  }
}

# Part 1B
# app can be accessed from any ip address TODO
resource "ibm_is_security_group_rule" "ingress_app_all" {
  group     = "${ibm_is_security_group.sg1.id}"
  direction = "inbound"
  remote    = "0.0.0.0/0"                       # TOO OPEN for production

  tcp = {
    port_min = 3000
    port_max = 3000
  }
}

resource "ibm_is_security_group_rule" "egress_161_26_112_108_all" {
  group     = "${ibm_is_security_group.sg1.id}"
  direction = "outbound"
  remote    = "0.0.0.0/0"                       # TOO OPEN for production
}

resource ibm_is_subnet "subnet1" {
  name                     = "${var.basename}-subnet1"
  vpc                      = "${ibm_is_vpc.vpc.id}"
  zone                     = "${var.zone}"
  total_ipv4_address_count = 256
}

data ibm_is_ssh_key "ssh_key" {
  name = "${var.ssh_key_name}"
}

data ibm_is_image "ubuntu" {
  name = "ubuntu-18.04-amd64"
}

resource ibm_is_instance "vsi1" {
  name           = "${var.basename}-vsi1"
  vpc            = "${ibm_is_vpc.vpc.id}"
  zone           = "${var.zone}"
  keys           = ["${data.ibm_is_ssh_key.ssh_key.id}"]
  image          = "${data.ibm_is_image.ubuntu.id}"
  profile        = "cc1-2x4"
  resource_group = "${data.ibm_resource_group.group.id}"

  primary_network_interface = {
    subnet          = "${ibm_is_subnet.subnet1.id}"
    security_groups = ["${ibm_is_security_group.sg1.id}"]
  }

  # Part 1B
  user_data = <<EOS
#!/bin/sh
apt update -y
apt install nodejs -y
cat > /app.js << 'EOF'
${replace(file("app/app.js"), "REMOTE_IP", aws_instance.vsi1.public_ip)}
EOF
cat > /lib/systemd/system/a-app.service << 'EOF'
${file("app/a-app.service")}
EOF
systemctl daemon-reload
systemctl start a-app
EOS
}

resource ibm_is_floating_ip "fip1" {
  name   = "${var.basename}-fip1"
  target = "${ibm_is_instance.vsi1.primary_network_interface.0.id}"
}

output ibm_public_ip {
  value = "${ibm_is_floating_ip.fip1.address}"
}
output ibm_private_ip {
  value = "${ibm_is_instance.vsi1.primary_network_interface.0.primary_ipv4_address}"
}
output ibm_ssh {
  value = "ssh root@${ibm_is_floating_ip.fip1.address}"
}
