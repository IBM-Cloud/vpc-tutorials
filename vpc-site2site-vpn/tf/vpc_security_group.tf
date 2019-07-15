resource ibm_is_security_group "sg_cloud" {
  name = "${var.resources_prefix}-sg"
  vpc  = "${ibm_is_vpc.vpc.id}"
}

resource "ibm_is_security_group_rule" "sg_cloud_ingress_tcp_80" {
  group     = "${ibm_is_security_group.sg_cloud.id}"
  direction = "ingress"
  remote    = "0.0.0.0/0"

  tcp = {
    port_min = 80
    port_max = 80
  }
}

resource "ibm_is_security_group_rule" "sg_cloud_ingress_tcp_443" {
  group     = "${ibm_is_security_group.sg_cloud.id}"
  direction = "ingress"
  remote    = "0.0.0.0/0"

  tcp = {
    port_min = 443
    port_max = 443
  }
}

resource "ibm_is_security_group_rule" "sg_cloud_ingress_tcp_22" {
  group     = "${ibm_is_security_group.sg_cloud.id}"
  direction = "ingress"
  remote    = "0.0.0.0/0"

  tcp = {
    port_min = 22
    port_max = 22
  }
}

resource "ibm_is_security_group_rule" "sg_cloud_ingress_icmp_8" {
  group     = "${ibm_is_security_group.sg_cloud.id}"
  direction = "ingress"
  remote    = "0.0.0.0/0"

  icmp = {
    type = 8
  }
}

resource "ibm_is_security_group_rule" "sg_cloud_egress_tcp_26257" {
  count     = 1
  group     = "${ibm_is_security_group.sg_cloud.id}"
  direction = "egress"
  remote    = "0.0.0.0/0"

}
