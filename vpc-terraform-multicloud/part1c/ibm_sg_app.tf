# SG to install software from IBM cloud mirrors private access to https, http and DNS access is required
resource "ibm_is_security_group" "install_software" {
  name = "${var.basename}-install-software"
  vpc  = ibm_is_vpc.vpc.id
}

resource "ibm_is_security_group_rule" "egress_443_all" {
  group     = ibm_is_security_group.install_software.id
  direction = "outbound"
  remote    = "161.26.0.6"
  tcp {
    port_min = 443
    port_max = 443
  }
}

resource "ibm_is_security_group_rule" "egress_80_all" {
  group     = ibm_is_security_group.install_software.id
  direction = "outbound"
  remote    = "161.26.0.6"
  tcp {
    port_min = 80
    port_max = 80
  }
}

resource "ibm_is_security_group_rule" "egress_dns_udp_10" {
  group     = ibm_is_security_group.install_software.id
  direction = "outbound"
  remote    = "161.26.0.10"
  udp {
    port_min = 53
    port_max = 53
  }
}

resource "ibm_is_security_group_rule" "egress_dns_udp_11" {
  group     = ibm_is_security_group.install_software.id
  direction = "outbound"
  remote    = "161.26.0.11"
  udp {
    port_min = 53
    port_max = 53
  }
}

