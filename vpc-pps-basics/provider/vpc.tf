module "provider_vpc" {
  source            = "../modules/vpc"
  resource_group_id = local.resource_group_id
  name              = "${var.basename}-provider-vpc"
  region            = var.region
  zones_to_cidrs = {
    "${var.region}-1" = "10.10.200.0/24"
  }
  tags              = var.tags
}

resource "ibm_is_security_group_rule" "inbound_http" {
  group     = module.provider_vpc.vpc_security_group.id
  direction = "inbound"
  tcp {
    port_max = 80
    port_min = 80
  }
}

resource "ibm_is_security_group_rule" "outbound_http" {
  group     = module.provider_vpc.vpc_security_group.id
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
  for_each = { for index, subnet in module.provider_vpc.vpc_subnets : index => subnet }

  name           = "${var.basename}-provider-vsi-${each.value.zone}"
  resource_group = local.resource_group_id
  image          = data.ibm_is_image.image.id
  profile        = var.instance_profile
  primary_network_interface {
    subnet = each.value.id
    security_groups = [
      module.provider_vpc.vpc_security_group.id
    ]
  }
  vpc  = module.provider_vpc.vpc.id
  zone = each.value.zone
  keys = [
    data.ibm_is_ssh_key.key.id
  ]

  user_data = file("./userdata.sh")
  tags      = concat(var.tags, ["vpc"])
}

resource "ibm_is_floating_ip" "ip" {
  for_each = {
    for index, subnet in module.provider_vpc.vpc_subnets : index => ibm_is_instance.instance[index]
    if var.create_floating_ips
  }

  name   = "${each.value.name}-ip"
  target = each.value.primary_network_interface[0].id
  resource_group = local.resource_group_id
}

output "connect_to_instance" {
 value = {
    for ip in ibm_is_floating_ip.ip: ip.name => "ssh root@${ip.address}"
  }
}

data "ibm_iam_auth_token" "tokendata" {}

provider "restapi" {
  alias = "pps"
  uri                  = local.iaas_endpoint
  debug                = true
  write_returns_object = true
  headers = {
    Authorization = data.ibm_iam_auth_token.tokendata.iam_access_token
  }
}

module "provider_pps" {
  source = "./modules/pps"

  basename = "${var.basename}"
  iaas_endpoint = local.iaas_endpoint
  iaas_endpoint_version = local.iaas_endpoint_version
  resource_group_id = local.resource_group_id
  subnet_id = module.provider_vpc.vpc_subnets[0].id
  instance_ids = [ for instance in ibm_is_instance.instance: instance.id ]
  tags = var.tags
  endpoint = "${var.basename}.example.com"

  providers = {
    restapi = restapi.pps
  }
}

output "pps" {
  value = module.provider_pps.pps
}
