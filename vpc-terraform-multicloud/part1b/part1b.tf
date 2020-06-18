# allow ssh access to this instance from anywhere on the planet, this is just for testing and messing about
/*
resource "ibm_is_security_group_rule" "sg1_ingress_ssh_all" {
  group     = ibm_is_security_group.sg1.id
  direction = "inbound"
  remote    = "0.0.0.0/0"                       # TOO OPEN for production

  tcp = {
    port_min = 22
    port_max = 22
  }
}
output ibm1_ssh {
  value = "ssh root@${ibm_is_floating_ip.vsi1.address}"
}
*/
# Add the ability to access the app endpoint from any ip address, like from a desktop try: curl IP:3000
resource "ibm_is_security_group_rule" "sg1_ingress_app_all" {
  group     = ibm_is_security_group.sg1.id
  direction = "inbound"
  remote    = "0.0.0.0/0"

  tcp {
    port_min = 3000
    port_max = 3000
  }
}
output ibm1_curl {
  value = <<EOS
curl ${ibm_is_floating_ip.vsi1.address}:3000; # get hello world string
curl ${ibm_is_floating_ip.vsi1.address}:3000/info; # get the private IP address
EOS
}
locals {
  ibm_vsi1_user_data = local.shared_app_user_data
  ibm_vsi1_security_groups = [ibm_is_security_group.sg1.id, ibm_is_security_group.install_software.id]
}
