resource "ibm_is_security_group" "sg" {
  name           = "${var.resources_prefix}-sg"
  vpc            = ibm_is_vpc.vpc.id
  resource_group = data.ibm_resource_group.group.id
}

resource "ibm_is_security_group_rule" "sg_inbound_tcp_22" {
  group     = ibm_is_security_group.sg.id
  direction = "inbound"
  remote    = "0.0.0.0/0"

  tcp {
    port_min = 22
    port_max = 22
  }
}

resource "ibm_is_security_group_rule" "sg_inbound_tcp_80" {
  group     = ibm_is_security_group.sg.id
  direction = "inbound"
  remote    = "0.0.0.0/0"

  tcp {
    port_min = 80
    port_max = 80
  }
}

resource "ibm_is_security_group_rule" "sg_outbound_iaas_endpoints" {
  group     = ibm_is_security_group.sg.id
  direction = "outbound"
  remote    = "161.26.0.0/16"
}

resource "ibm_is_security_group_rule" "sg_outbound_tcp_53" {
  group     = ibm_is_security_group.sg.id
  direction = "outbound"
  remote    = "0.0.0.0/0"

  tcp {
    port_min = 53
    port_max = 53
  }
}

resource "ibm_is_security_group_rule" "sg_outbound_udp_53" {
  group     = ibm_is_security_group.sg.id
  direction = "outbound"
  remote    = "0.0.0.0/0"

  udp {
    port_min = 53
    port_max = 53
  }
}

resource "ibm_is_security_group_rule" "sg_outbound_tcp_443" {
  group     = ibm_is_security_group.sg.id
  direction = "outbound"
  remote    = "0.0.0.0/0"

  tcp {
    port_min = 443
    port_max = 443
  }
}

resource "ibm_is_security_group_rule" "sg_outbound_tcp_80" {
  group     = ibm_is_security_group.sg.id
  direction = "outbound"
  remote    = "0.0.0.0/0"

  tcp {
    port_min = 80
    port_max = 80
  }
}

resource "ibm_is_subnet" "sub" {
  count                    = "1"
  name                     = "${var.resources_prefix}-sub-1"
  vpc                      = ibm_is_vpc.vpc.id
  zone                     = "${var.vpc_region}-1"
  total_ipv4_address_count = 16
  resource_group           = data.ibm_resource_group.group.id
}

resource "ibm_is_volume" "vsi_data_volume" {
  count          = tobool(var.byok_data_volume) == true ? 1 : 0
  name           = "${var.resources_prefix}-data-${count.index + 1}"
  profile        = "custom"
  zone           = "${var.vpc_region}-1"
  iops           = 6000
  capacity       = 100
  resource_group = data.ibm_resource_group.group.id

  encryption_key =  ibm_kp_key.key_protect.0.crn
}

data "ibm_is_image" "image_name" {
  name = var.vpc_image_name
}

resource "ibm_is_instance" "vpc_vsi" {
  count          = 1
  name           = "${var.resources_prefix}-vsi"
  vpc            = ibm_is_vpc.vpc.id
  zone           = "${var.vpc_region}-1" 
  keys           = ["${data.ibm_is_ssh_key.ssh_key.id}"]
  image          = data.ibm_is_image.image_name.id
  profile        = var.vpc_image_profile
  resource_group = data.ibm_resource_group.group.id

  primary_network_interface {
    subnet          = element(ibm_is_subnet.sub.*.id, count.index)
    security_groups = [ibm_is_security_group.sg.id]
  }

  volumes = tobool(var.byok_data_volume) == true ? [ibm_is_volume.vsi_data_volume[0].id] : []
}

resource "ibm_is_floating_ip" "vpc_vsi_fip" {
  count          = 1
  name           = "${var.resources_prefix}-vsi-fip"
  target         = ibm_is_instance.vpc_vsi.0.primary_network_interface.0.id
  resource_group = data.ibm_resource_group.group.id
}

