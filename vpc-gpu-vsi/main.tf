data "ibm_is_image" "vsi_image" {
  name = var.vsi_image_name
}

data "ibm_is_ssh_key" "ssh_key" {
  name = var.ssh_keyname
}

data "ibm_resource_group" "group" {
  name = var.resource_group_name
}

resource "ibm_is_vpc" "vpc" {
  name           = var.vpc_name
  resource_group = data.ibm_resource_group.group.id
}

resource "ibm_is_subnet" "subnet" {
  name                     = "${var.basename}-subnet"
  vpc                      = ibm_is_vpc.vpc.id
  zone                     = var.subnet_zone
  resource_group           = data.ibm_resource_group.group.id
  total_ipv4_address_count = 64
}

resource "ibm_is_instance" "instance" {
  name           = "${var.basename}-instance"
  vpc            = ibm_is_vpc.vpc.id
  zone           = var.subnet_zone
  profile        = "gx2-8x64x1v100"
  image          = data.ibm_is_image.vsi_image.id
  keys           = [data.ibm_is_ssh_key.ssh_key.id]
  resource_group = data.ibm_resource_group.group.id

  primary_network_interface {
    subnet = ibm_is_subnet.subnet.id
  }
  user_data = <<-EOS
    #!/bin/bash
    wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/x86_64/cuda-ubuntu2004.pin
    sudo mv cuda-ubuntu2004.pin /etc/apt/preferences.d/cuda-repository-pin-600
    sudo apt-key adv --fetch-keys https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/x86_64/7fa2af80.pub
    sudo add-apt-repository "deb https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/x86_64/ /"
    curl https://get.docker.com | sh \
    && sudo systemctl --now enable docker
    distribution=$(. /etc/os-release;echo $ID$VERSION_ID) \
    && curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add - \
    && curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list
    sudo apt-get update
    sudo apt-get -y install cuda
    sudo apt-get install -y nvidia-docker2
    sudo systemctl restart docker
  EOS
}

resource "ibm_is_floating_ip" "floatingip" {
  name   = "${var.basename}-instance-fip"
  target = ibm_is_instance.instance.primary_network_interface[0].id
}

resource "ibm_is_security_group" "group" {
  name           = "${var.basename}-group"
  resource_group = data.ibm_resource_group.group.id
  vpc            = ibm_is_vpc.vpc.id
}

#######################################################
# Security group OUTbound rules
#######################################################

resource "ibm_is_security_group_rule" "tcp_80" {
  group     = ibm_is_security_group.group.id
  direction = "outbound"
  remote    = "0.0.0.0/0"

  tcp {
    port_min = 80
    port_max = 80
  }
}

resource "ibm_is_security_group_rule" "tcp_443" {
  group     = ibm_is_security_group.group.id
  direction = "outbound"
  remote    = "0.0.0.0/0"

  tcp {
    port_min = 443
    port_max = 443
  }
}

resource "ibm_is_security_group_rule" "tcp_53" {
  group     = ibm_is_security_group.group.id
  direction = "outbound"
  remote    = "0.0.0.0/0"

  tcp {
    port_min = 53
    port_max = 53
  }
}

resource "ibm_is_security_group_rule" "udp_443" {
  group     = ibm_is_security_group.group.id
  direction = "outbound"
  remote    = "0.0.0.0/0"

  udp {
    port_min = 53
    port_max = 53
  }
}

#######################################################
# Security group INbound rules
#######################################################

resource "ibm_is_security_group_rule" "ssh" {
  group     = ibm_is_security_group.group.id
  direction = "inbound"
  remote    = "0.0.0.0/0"

  tcp {
    port_min = 22
    port_max = 22
  }
}

resource "ibm_is_security_group_rule" "ping" {
  group     = ibm_is_security_group.group.id
  direction = "inbound"
  remote    = "0.0.0.0/0"

  icmp {
    type = 8
  }
}

resource "ibm_is_security_group_rule" "jupyter_notebook_8888" {
  group     = ibm_is_security_group.group.id
  direction = "inbound"
  remote    = "0.0.0.0/0"

  tcp {
    port_min = 8888
    port_max = 8888
  }
}

resource "ibm_is_security_group_network_interface_attachment" "add_to_group" {
  security_group    = ibm_is_security_group.group.id
  network_interface = ibm_is_instance.instance.primary_network_interface.0.id
}