resource ibm_is_security_group "sg_maintenance" {
  name = "${var.vpc_maintenance_security_group_name}"
  vpc  = "${var.vpc_id}"
}

resource "ibm_is_security_group_rule" "sg_maintenance_ingress_tcp_22" {
  group     = "${ibm_is_security_group.sg_maintenance.id}"
  direction = "ingress"
  remote = "${ibm_is_security_group.sg_bastion.id}"

  tcp = {
    port_min = 22
    port_max = 22
  }
}

resource "ibm_is_security_group_rule" "sg_maintenance_egress_tcp_53" {
  group     = "${ibm_is_security_group.sg_maintenance.id}"
  direction = "egress"
  remote    = "0.0.0.0/0"

  tcp = {
    port_min = 53
    port_max = 53
  }
}

resource "ibm_is_security_group_rule" "sg_maintenance_egress_udp_53" {
  group     = "${ibm_is_security_group.sg_maintenance.id}"
  direction = "egress"
  remote    = "0.0.0.0/0"

  udp = {
    port_min = 53
    port_max = 53
  }
}

resource "ibm_is_security_group_rule" "sg_maintenance_egress_tcp_443" {
  group     = "${ibm_is_security_group.sg_maintenance.id}"
  direction = "egress"
  remote    = "0.0.0.0/0"

  tcp = {
    port_min = 443
    port_max = 443
  }
}

resource "ibm_is_security_group_rule" "sg_maintenance_egress_tcp_80" {
  group     = "${ibm_is_security_group.sg_maintenance.id}"
  direction = "egress"
  remote    = "0.0.0.0/0"

  tcp = {
    port_min = 80
    port_max = 80
  }
}
