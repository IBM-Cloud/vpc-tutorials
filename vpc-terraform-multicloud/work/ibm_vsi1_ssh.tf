# allow ssh access to this instance from anywhere on the planet, this is just for testing and messing about
resource "ibm_is_security_group_rule" "sg1_ingress_ssh_all" {
  group     = ibm_is_security_group.sg1.id
  direction = "inbound"
  remote    = "0.0.0.0/0" # TOO OPEN for production

  tcp {
    port_min = 22
    port_max = 22
  }
}

output "ibm1_ssh" {
  value = "ssh root@${ibm_is_floating_ip.vsi1.address}"
}

