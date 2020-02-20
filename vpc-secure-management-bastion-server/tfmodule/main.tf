# Users of this module need to apply the SG to instance to get access through the bastian
resource "ibm_is_security_group" "maintenance" {
  name           = "${var.basename}-maintenance-sg"
  vpc            = var.ibm_is_vpc_id
  resource_group = var.ibm_is_resource_group_id
}

resource "ibm_is_security_group_rule" "maintenance_ingress_ssh_bastion" {
  group     = ibm_is_security_group.maintenance.id
  direction = "inbound"
  remote    = ibm_is_security_group.bastion.id

  tcp {
    port_min = 22
    port_max = 22
  }
}

# this is the SG applied to the bastian instance
resource "ibm_is_security_group" "bastion" {
  name           = "${var.basename}-bastion-sg"
  vpc            = var.ibm_is_vpc_id
  resource_group = var.ibm_is_resource_group_id
}

# users of the bastian. for example from on premises
resource "ibm_is_security_group_rule" "bastion_ingress_ssh_all" {
  group     = ibm_is_security_group.bastion.id
  direction = "inbound"
  remote    = var.remote

  tcp {
    port_min = 22
    port_max = 22
  }
}

resource "ibm_is_security_group_rule" "bastion_egress_ssh_maintenance" {
  group     = ibm_is_security_group.bastion.id
  direction = "outbound"
  remote    = ibm_is_security_group.maintenance.id

  tcp {
    port_min = 22
    port_max = 22
  }
}

resource "ibm_is_instance" "bastion" {
  name    = "${var.basename}-bastion-vsi"
  image   = var.ibm_is_image_id
  profile = var.profile

  primary_network_interface {
    subnet          = var.ibm_is_subnet_id
    security_groups = [ibm_is_security_group.bastion.id]
  }

  vpc            = var.ibm_is_vpc_id
  zone           = var.zone
  resource_group = var.ibm_is_resource_group_id
  keys           = [var.ibm_is_ssh_key_id]
}

resource "ibm_is_floating_ip" "bastion" {
  name           = "${var.basename}-bastion-ip"
  target         = ibm_is_instance.bastion.primary_network_interface[0].id
  resource_group = var.ibm_is_resource_group_id
}

/*
# optional
resource "ibm_is_security_group_rule" "maintenance_egress_443" {
  group     = "${ibm_is_security_group.maintenance.id}"
  direction = "outbound"
  remote    = "0.0.0.0/0"
  tcp = {
    port_min = 443
    port_max = 443
  }
}
# optional
resource "ibm_is_security_group_rule" "maintenance_egress_80" {
  group     = "${ibm_is_security_group.maintenance.id}"
  direction = "outbound"
  remote    = "0.0.0.0/0"
  tcp = {
    port_min = 80
    port_max = 80
  }
}
# optional
resource "ibm_is_security_group_rule" "maintenance_egress_53" {
  group     = "${ibm_is_security_group.maintenance.id}"
  direction = "outbound"
  remote    = "0.0.0.0/0"
  tcp = {
    port_min = 53
    port_max = 53
  }
}
# optional
resource "ibm_is_security_group_rule" "maintenance_egress_udp_53" {
  group     = "${ibm_is_security_group.maintenance.id}"
  direction = "outbound"
  remote    = "0.0.0.0/0"
  udp = {
    port_min = 53
    port_max = 53
  }
}
# optional
resource "ibm_is_security_group_rule" "bastion_ingress_icmp_all" {
  group     = "${ibm_is_security_group.bastion.id}"
  direction = "inbound"
  remote    = "0.0.0.0/0"
  icmp = {
    type = 8
    code = 0
  }
}
*/
