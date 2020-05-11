# introduce a second subnet, vsi and associated security group
# SG only needs to allow access from vsi1, see sg1 below

resource "ibm_is_subnet" "subnet2" {
  name                     = "${var.basename}-subnet2"
  vpc                      = ibm_is_vpc.vpc.id
  zone                     = var.ibm_zones[1]
  total_ipv4_address_count = 256
}

resource "ibm_is_security_group" "sg2" {
  name = "${var.basename}-sg2"
  vpc  = ibm_is_vpc.vpc.id
}

resource "ibm_is_security_group_rule" "sg2_ingress_all" {
  group     = ibm_is_security_group.sg2.id
  direction = "inbound"
  remote    = ibm_is_security_group.sg1.id
  tcp {
    port_min = 3000
    port_max = 3000
  }
}

# vsi1/app needs access to vsi2/app
resource "ibm_is_security_group_rule" "sg1_egress_app_all" {
  group     = ibm_is_security_group.sg1.id
  direction = "outbound"
  remote    = ibm_is_security_group.sg2.id
  tcp {
    port_min = 3000
    port_max = 3000
  }
}

resource "ibm_is_instance" "vsi2" {
  name    = "${var.basename}-vsi2"
  vpc     = ibm_is_vpc.vpc.id
  zone    = var.ibm_zones[1]
  keys    = [data.ibm_is_ssh_key.ssh_key.id]
  image   = data.ibm_is_image.ubuntu.id
  profile = var.profile[var.generation]

  primary_network_interface {
    subnet          = ibm_is_subnet.subnet2.id
    security_groups = [ibm_is_security_group.sg2.id, ibm_is_security_group.install_software.id]
  }
  user_data = local.shared_app_user_data
}

output "ibm2_private_ip" {
  value = ibm_is_instance.vsi2.primary_network_interface[0].primary_ipv4_address
}

