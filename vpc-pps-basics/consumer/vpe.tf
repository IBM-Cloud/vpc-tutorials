data "ibm_iam_auth_token" "tokendata" {}

provider "restapi" {
  uri                  = local.iaas_endpoint
  debug                = true
  write_returns_object = true
  headers = {
    Authorization = data.ibm_iam_auth_token.tokendata.iam_access_token
  }
}

resource "ibm_is_subnet_reserved_ip" "vpe" {
  for_each = { for index, subnet in module.consumer_vpc.vpc_subnets : index => subnet }

  subnet = each.value.id
  name = "${var.basename}-consumer-to-provider-${each.value.zone}-ip"
}

resource "restapi_object" "vpe" {
  path         = "/v1/endpoint_gateways"
  query_string = local.iaas_endpoint_version
  data = jsonencode({
    name = "${var.basename}-consumer-to-provider"
    resource_group = {
      id = local.resource_group_id
    }
    target = {
      resource_type = "private_path_service_gateway"
      crn = var.provider_crn
    }
    security_groups = [
      {
        id = module.consumer_vpc.vpc_security_group.id
      }
    ]
    vpc = {
      id = module.consumer_vpc.vpc.id
    }
    ips = [ for ip in ibm_is_subnet_reserved_ip.vpe : {
      id = ip.reserved_ip
    }]
  })
  id_attribute = "id"

  lifecycle {
    ignore_changes = [
      query_string
    ]
  }
}

output "pps_curl_with_ip" {
  value = [
    for ip in ibm_is_subnet_reserved_ip.vpe:
      "curl http://${ip.address}"
  ]
}

output "pps_curl_with_url" {
  value = "curl http://${restapi_object.vpe.api_data.service_endpoint}"
}
