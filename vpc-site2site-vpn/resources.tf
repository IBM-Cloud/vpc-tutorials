# resources - postgresql and cloud object storage with associated endpoint gateway and security groups

//------------------------------------------------
// postgresql
resource "ibm_database" "postgresql" {
  name              = "${local.BASENAME_CLOUD}-pg"
  resource_group_id = data.ibm_resource_group.all_rg.id
  plan              = "standard"
  service           = "databases-for-postgresql"
  location          = var.region
  service_endpoints = "private"
  tags              = local.tags
}

resource "ibm_resource_key" "postgresql" {
  name                 = "${local.BASENAME_CLOUD}-pg-key"
  resource_instance_id = ibm_database.postgresql.id
  role = "Administrator"
  tags = local.tags
}

resource "time_sleep" "wait_for_postgresql_initialization" {
  depends_on = [
    ibm_database.postgresql
  ]
  create_duration = "5m"
}
resource "ibm_is_security_group" "postgresql" {
  name           = "${local.BASENAME_CLOUD}-postgresql"
  vpc            = ibm_is_vpc.cloud.id
  resource_group = data.ibm_resource_group.all_rg.id
}

resource "ibm_is_security_group_rule" "cloud_ingress_postgresql" {
  group     = ibm_is_security_group.postgresql.id
  direction = "inbound"
  remote    = "10.0.0.0/8" // on prem and cloud
  tcp {
    port_min = local.postgresql_port
    port_max = local.postgresql_port
  }
}

resource "ibm_is_security_group_rule" "cloud_egress_postgresql" {
  group     = ibm_is_security_group.postgresql.id
  direction = "outbound"
  remote    = "10.0.0.0/8" // on prem and cloud
}

// race condition the security group deletion after endpoint_gateway is deleted
// virtual_endpoint_gateway -> time_sleep -> security_group the delete in the reverse order means a 10s delay before delete of sg
// https://github.com/IBM-Cloud/terraform-provider-ibm/issues/3780
resource "time_sleep" "wait_for_security_group_delete_postgresql" {
  depends_on       = [ibm_is_security_group.postgresql]
  destroy_duration = "10s"
}

resource "ibm_is_virtual_endpoint_gateway" "postgresql" {
  depends_on = [
    time_sleep.wait_for_postgresql_initialization,
    time_sleep.wait_for_security_group_delete_postgresql,
  ]
  vpc            = ibm_is_vpc.cloud.id
  name           = local.BASENAME_CLOUD
  resource_group = data.ibm_resource_group.all_rg.id
  target {
    crn           = ibm_database.postgresql.id
    resource_type = "provider_cloud_service"
  }
  security_groups = [ibm_is_security_group.postgresql.id]

  # one Reserved IP per zone in the VPC
  ips {
    subnet = ibm_is_subnet.cloud.id
    name   = "postgresql"
  }
  tags = local.tags
}
locals {
  postgresql_credentials = jsonencode(nonsensitive(ibm_resource_key.postgresql.credentials))
}

//------------------------------------------------
// cos
# cos 
locals {
  # reverse engineer this by creating one by hand:
  cos_endpoint = "s3.direct.${var.region}.cloud-object-storage.appdomain.cloud"
}
resource "ibm_resource_instance" "cos" {
  name              = "${local.BASENAME_CLOUD}-cos"
  resource_group_id = data.ibm_resource_group.all_rg.id
  service           = "cloud-object-storage"
  plan              = "standard"
  location          = "global"
  tags              = local.tags
}

resource "ibm_resource_key" "cos" {
  name                 = "${local.BASENAME_CLOUD}-cos-key"
  resource_instance_id = ibm_resource_instance.cos.id
  role                 = "Writer"

  parameters = {
    service-endpoints = "private"
  }
  tags = local.tags
}

resource "ibm_is_security_group" "cos" {
  name           = "${local.BASENAME_CLOUD}-cos"
  vpc            = ibm_is_vpc.cloud.id
  resource_group = data.ibm_resource_group.all_rg.id
}

resource "ibm_is_security_group_rule" "cloud_ingress_cos" {
  group     = ibm_is_security_group.cos.id
  direction = "inbound"
  remote    = "10.0.0.0/8" // on prem and cloud
  tcp {
    port_min = 443
    port_max = 443
  }
}
resource "ibm_is_security_group_rule" "cloud_egress_cos" {
  group     = ibm_is_security_group.cos.id
  direction = "outbound"
  remote    = "10.0.0.0/8" // on prem and cloud
}

// race condition the security group deletion after endpoint_gateway is deleted
// virtual_endpoint_gateway -> time_sleep -> security_group the delete in the reverse order means a 10s delay before delete of sg
// https://github.com/IBM-Cloud/terraform-provider-ibm/issues/3780
resource "time_sleep" "wait_for_security_group_delete_cos" {
  depends_on       = [ibm_is_security_group.cos]
  destroy_duration = "10s"
}

resource "ibm_is_virtual_endpoint_gateway" "cos" {
  depends_on     = [time_sleep.wait_for_security_group_delete_cos]
  vpc            = ibm_is_vpc.cloud.id
  name           = "${local.BASENAME_CLOUD}-cos"
  resource_group = data.ibm_resource_group.all_rg.id
  target {
    crn           = "crn:v1:bluemix:public:cloud-object-storage:global:::endpoint:${local.cos_endpoint}"
    resource_type = "provider_cloud_service"
  }

  security_groups = [ibm_is_security_group.cos.id]

  # one Reserved IP per zone in the VPC
  ips {
    subnet = ibm_is_subnet.cloud.id
    name   = "cos"
  }
  tags = local.tags
}
