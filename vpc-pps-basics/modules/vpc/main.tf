resource "ibm_is_vpc" "vpc" {
  name                      = var.name
  resource_group            = var.resource_group_id
  address_prefix_management = "manual"
  tags                      = concat(var.tags, ["vpc"])
  no_sg_acl_rules           = true
}

output "vpc" {
  value = ibm_is_vpc.vpc
}

output "vpc_subnets" {
  value = ibm_is_subnet.subnet
}

output "vpc_security_group" {
  value = ibm_is_security_group.default
}

resource "ibm_is_vpc_address_prefix" "subnet_prefix" {
  count = length(local.cidrs)

  name = "${var.name}-${local.zones[count.index]}"
  zone = local.zones[count.index]
  vpc  = ibm_is_vpc.vpc.id
  cidr = local.cidrs[count.index]
}

resource "ibm_is_network_acl" "network_acl" {
  name           = "${var.name}-acl"
  vpc            = ibm_is_vpc.vpc.id
  resource_group = var.resource_group_id

  rules {
    name        = "egress"
    action      = "allow"
    source      = "0.0.0.0/0"
    destination = "0.0.0.0/0"
    direction   = "outbound"
  }
  rules {
    name        = "ingress"
    action      = "allow"
    source      = "0.0.0.0/0"
    destination = "0.0.0.0/0"
    direction   = "inbound"
  }
  tags            = local.tags
}

resource "ibm_is_subnet" "subnet" {
  count = length(local.zones)

  name            = "${var.name}-${local.zones[count.index]}"
  vpc             = ibm_is_vpc.vpc.id
  zone            = local.zones[count.index]
  resource_group  = var.resource_group_id
  ipv4_cidr_block = ibm_is_vpc_address_prefix.subnet_prefix[count.index].cidr
  network_acl     = ibm_is_network_acl.network_acl.id
  public_gateway  = ibm_is_public_gateway.gateway[count.index].id
  tags            = local.tags
}

resource "ibm_is_public_gateway" "gateway" {
  count = length(local.zones)

  name           = "${var.name}-${local.zones[count.index]}"
  vpc            = ibm_is_vpc.vpc.id
  zone           = local.zones[count.index]
  resource_group = var.resource_group_id
  tags            = local.tags
}

resource "ibm_is_security_group" "default" {
  name           = "${var.name}-group"
  vpc            = ibm_is_vpc.vpc.id
  resource_group = var.resource_group_id
  tags            = local.tags
}

resource "ibm_is_security_group_rule" "outbound_https" {
  group     = ibm_is_security_group.default.id
  direction = "outbound"
  tcp {
    port_max = 443
    port_min = 443
  }
}

resource "ibm_is_security_group_rule" "outbound_dns" {
  group     = ibm_is_security_group.default.id
  direction = "outbound"
  udp {
    port_max = 53
    port_min = 53
  }
}

resource "ibm_is_security_group_rule" "outbound_cse" {
  group     = ibm_is_security_group.default.id
  direction = "outbound"
  remote    = "166.9.0.0/16"
}

# from https://cloud.ibm.com/docs/vpc?topic=vpc-service-endpoints-for-vpc
resource "ibm_is_security_group_rule" "outbound_private" {
  group     = ibm_is_security_group.default.id
  direction = "outbound"
  remote    = "161.26.0.0/16"
}

resource "ibm_is_security_group_rule" "inbound_ssh" {
  group     = ibm_is_security_group.default.id
  direction = "inbound"
  tcp {
    port_min = 22
    port_max = 22
  }
}

resource "ibm_is_security_group_rule" "inbound_ping" {
  group     = ibm_is_security_group.default.id
  direction = "inbound"
  icmp {
    type = 8
  }
}

resource "ibm_is_security_group_rule" "outbound_ssh" {
  group     = ibm_is_security_group.default.id
  direction = "outbound"
  tcp {
    port_min = 22
    port_max = 22
  }
}

resource "ibm_is_security_group_rule" "outbound_ping" {
  group     = ibm_is_security_group.default.id
  direction = "outbound"
  icmp {
    type = 8
  }
}