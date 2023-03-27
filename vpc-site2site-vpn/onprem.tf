# onprem vpc resources

locals {
  onprem_user_data = <<-EOT
    ${file("${path.module}/user_data/onprem.sh")}
    ${local.onprem_config}
  EOT

  onprem_config = <<-EOT
    ONPREM_CIDR=${local.cidr_onprem}
    GW_CLOUD_IP=${local.GW_CLOUD_IP}
    PRESHARED_KEY=${local.PRESHARED_KEY}
    CLOUD_CIDR=${local.cidr_cloud}
    DNS_SERVER_IP0=${local.DNS_SERVER_IP0}
    DNS_SERVER_IP1=${local.DNS_SERVER_IP1}
    # call main function
    main
  EOT
}

resource "ibm_is_vpc" "onprem" {
  name                      = local.BASENAME_ONPREM
  tags                      = local.tags
  resource_group            = data.ibm_resource_group.all_rg.id
  address_prefix_management = "manual"
}

resource "ibm_is_vpc_address_prefix" "onprem" {
  name = local.zone
  zone = local.zone
  vpc  = ibm_is_vpc.onprem.id
  cidr = local.cidr_onprem_1
}

resource "ibm_is_subnet" "onprem" {
  depends_on      = [ibm_is_vpc_address_prefix.onprem]
  name            = "${local.BASENAME_ONPREM}-subnet"
  vpc             = ibm_is_vpc.onprem.id
  zone            = local.zone
  ipv4_cidr_block = local.cidr_onprem_subnet
  resource_group  = data.ibm_resource_group.all_rg.id
}

// ssh only - should narrow down to just IP addresses that are applicable
resource "ibm_is_security_group_rule" "onprem_inbound_all" {
  group     = ibm_is_vpc.onprem.default_security_group
  direction = "inbound"
  remote    = "0.0.0.0/0"
  tcp {
    port_min = "22"
    port_max = "22"
  }
}

// Need to at least: install software, VPN remote, postgresql and object storage
resource "ibm_is_security_group_rule" "onprem_outbound_all" {
  group     = ibm_is_vpc.onprem.default_security_group
  direction = "outbound"
  remote    = "0.0.0.0/0"
}

resource "ibm_is_instance" "onprem" {
  name           = local.BASENAME_ONPREM
  image          = data.ibm_is_image.os.id
  profile        = var.profile
  vpc            = ibm_is_vpc.onprem.id
  zone           = local.zone
  keys           = [data.ibm_is_ssh_key.sshkey.id]
  resource_group = data.ibm_resource_group.all_rg.id
  user_data      = local.onprem_user_data
  metadata_service {
    enabled = true
  }
  primary_network_interface {
    subnet = ibm_is_subnet.onprem.id
  }
}

resource "ibm_is_floating_ip" "onprem" {
  tags           = local.tags
  resource_group = data.ibm_resource_group.all_rg.id
  name           = "${local.BASENAME_ONPREM}-onprem-vsi"
  target         = ibm_is_instance.onprem.primary_network_interface[0].id
}