# cloud dns and dns resolver with location

resource "ibm_resource_instance" "dns" {
  name              = local.BASENAME_CLOUD
  resource_group_id = data.ibm_resource_group.all_rg.id
  location          = "global"
  service           = "dns-svcs"
  plan              = "standard-dns"
}

// configure custom resolvers with a minimum of two resolver locations.
resource "ibm_dns_custom_resolver" "location" {
  name        = "${local.BASENAME_CLOUD}-cloud"
  instance_id = ibm_resource_instance.dns.guid
  description = "onprem uses this resolver to find the vpc endpoint gateways for postgresql and COS"
  locations {
    subnet_crn = ibm_is_subnet.cloud.crn
    enabled    = true
  }
  locations {
    subnet_crn = ibm_is_subnet.bastion.crn
    enabled    = true
  }
}
