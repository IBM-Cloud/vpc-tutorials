module "consumer_vpc" {
  source            = "../modules/vpc"
  resource_group_id = local.resource_group_id
  name              = "${var.basename}-consumer-vpc"
  region            = var.region
  zones_to_cidrs = {
    "${var.region}-1" = "10.10.100.0/24",
    "${var.region}-2" = "10.10.120.0/24",
  }
  tags              = var.tags
}

resource "ibm_is_security_group_rule" "inbound_http" {
  group     = module.consumer_vpc.vpc_security_group.id
  direction = "inbound"
  tcp {
    port_max = 80
    port_min = 80
  }
}

resource "ibm_is_security_group_rule" "outbound_http" {
  group     = module.consumer_vpc.vpc_security_group.id
  direction = "outbound"
  tcp {
    port_max = 80
    port_min = 80
  }
}

data "ibm_is_image" "image" {
  name = "ibm-centos-stream-9-amd64-8"
}

data "ibm_is_ssh_key" "key" {
  name = var.existing_ssh_key_name
}

resource "ibm_is_instance" "instance" {
  for_each = { for index, subnet in module.consumer_vpc.vpc_subnets: index => subnet }

  name           = "${var.basename}-consumer-vsi-${each.value.zone}"
  resource_group = local.resource_group_id
  image          = data.ibm_is_image.image.id
  profile        = var.instance_profile
  primary_network_interface {
    subnet = each.value.id
    security_groups = [
      module.consumer_vpc.vpc_security_group.id
    ]
  }
  vpc  = each.value.vpc
  zone = each.value.zone
  keys = [
    data.ibm_is_ssh_key.key.id
  ]

  user_data = file("./userdata.sh")
  tags      = concat(var.tags, ["vpc"])
}

resource "ibm_is_floating_ip" "ip" {
  for_each = ibm_is_instance.instance

  name   = "${each.value.name}-ip"
  target = each.value.primary_network_interface[0].id
  resource_group = local.resource_group_id
}

output "connect_to_instance" {
 value = [
    for ip in ibm_is_floating_ip.ip: {
      "${ip.name}" = "ssh root@${ip.address}"
    }
  ]
}
