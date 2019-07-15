resource ibm_is_security_group "sg_bastion" {
  name = "${var.vpc_vsi_security_group_name}"
  vpc  = "${var.vpc_id}"
}

resource "ibm_is_security_group_rule" "sg_bastion_ingress_tcp_22" {
  group     = "${ibm_is_security_group.sg_bastion.id}"
  direction = "ingress"
  remote    = "0.0.0.0/0"

  tcp = {
    port_min = 22
    port_max = 22
  }
}

resource "ibm_is_security_group_rule" "sg_bastion_egress_tcp_22" {
  group     = "${ibm_is_security_group.sg_bastion.id}"
  direction = "egress"
  remote    = "${ibm_is_security_group.sg_bastion.id}"

  tcp = {
    port_min = 22
    port_max = 22
  }
}
