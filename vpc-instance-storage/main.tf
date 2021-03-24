data "ibm_resource_group" "group" {
  name = var.resource_group
}

#Create a ssh keypair which will be used to provision code onto the system - and also access the VM for debug if needed.
resource "tls_private_key" "build_key" {
  count = var.ssh_private_key_format == "build" ? 1 : 0
  algorithm = "RSA"
  rsa_bits = "4096"
}

resource "ibm_is_vpc" "vpc" {
  name           = "${var.resources_prefix}-vpc"
  resource_group = data.ibm_resource_group.group.id
}

resource "ibm_is_ssh_key" "build_key" {
  count = var.ssh_private_key_format == "build" ? 1 : 0
  name = "${var.resources_prefix}-build-key"
  public_key = tls_private_key.build_key.0.public_key_openssh
  resource_group = data.ibm_resource_group.group.id
}

data "ibm_is_ssh_key" "ssh_key" {
  name = var.vpc_ssh_key
}

resource "ibm_is_public_gateway" "pgw" {
  count = 1
  name  = "${var.resources_prefix}-pgw-${count.index + 1}"
  vpc   = ibm_is_vpc.vpc.id
  zone  = "${var.vpc_region}-${count.index + 1}"
  resource_group = data.ibm_resource_group.group.id
}

resource "ibm_is_security_group" "sg_maintenance" {
  name           = "${var.resources_prefix}-sg-maintenance"
  vpc            = ibm_is_vpc.vpc.id
  resource_group = data.ibm_resource_group.group.id
}

resource "ibm_is_security_group_rule" "sg_maintenance_inbound_tcp_22" {
  group     = ibm_is_security_group.sg_maintenance.id
  direction = "inbound"
  remote    = "0.0.0.0/0"

  tcp {
    port_min = 22
    port_max = 22
  }
}

resource "ibm_is_security_group_rule" "sg_maintenance_outbound_iaas_endpoints" {
  group     = ibm_is_security_group.sg_maintenance.id
  direction = "outbound"
  remote    = "161.26.0.0/16"
}

resource "ibm_is_security_group_rule" "sg_maintenance_outbound_tcp_53" {
  group     = ibm_is_security_group.sg_maintenance.id
  direction = "outbound"
  remote    = "0.0.0.0/0"

  tcp {
    port_min = 53
    port_max = 53
  }
}

resource "ibm_is_security_group_rule" "sg_maintenance_outbound_udp_53" {
  group     = ibm_is_security_group.sg_maintenance.id
  direction = "outbound"
  remote    = "0.0.0.0/0"

  udp {
    port_min = 53
    port_max = 53
  }
}

resource "ibm_is_security_group_rule" "sg_maintenance_outbound_tcp_443" {
  group     = ibm_is_security_group.sg_maintenance.id
  direction = "outbound"
  remote    = "0.0.0.0/0"

  tcp {
    port_min = 443
    port_max = 443
  }
}

resource "ibm_is_security_group_rule" "sg_maintenance_outbound_tcp_80" {
  group     = ibm_is_security_group.sg_maintenance.id
  direction = "outbound"
  remote    = "0.0.0.0/0"

  tcp {
    port_min = 80
    port_max = 80
  }
}

resource "ibm_is_subnet" "sub_app" {
  count                    = 1
  name                     = "${var.resources_prefix}-sub-app-${count.index + 1}"
  vpc                      = ibm_is_vpc.vpc.id
  zone                     = "${var.vpc_region}-${count.index + 1}"
  total_ipv4_address_count = 16
  public_gateway           = element(ibm_is_public_gateway.pgw.*.id, count.index)
  resource_group           = data.ibm_resource_group.group.id
}

data "ibm_is_image" "app_image_name" {
  name = var.vpc_app_image_name
}

resource "ibm_is_instance" "vsi_app" {
  count          = 1
  name           = "${var.resources_prefix}-vsi-app-${count.index + 1}"
  vpc            = ibm_is_vpc.vpc.id
  zone           = "${var.vpc_region}-${count.index + 1}"
  keys           = var.ssh_private_key_format == "build" ? concat(data.ibm_is_ssh_key.ssh_key.*.id, [ibm_is_ssh_key.build_key.0.id]) : data.ibm_is_ssh_key.ssh_key.*.id
  image          = data.ibm_is_image.app_image_name.id
  profile        = var.vpc_app_image_profile
  resource_group = data.ibm_resource_group.group.id

  primary_network_interface {
    subnet          = element(ibm_is_subnet.sub_app.*.id, count.index)
    security_groups = [ibm_is_security_group.sg_maintenance.id]
  }
}

resource "ibm_is_floating_ip" "vpc_vsi_app_fip" {
  count          = 1
  name           = "${var.resources_prefix}-vsi-app-fip"
  target         = ibm_is_instance.vsi_app[0].primary_network_interface[0].id
  resource_group = data.ibm_resource_group.group.id
}
