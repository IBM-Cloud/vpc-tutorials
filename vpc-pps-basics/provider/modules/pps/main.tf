resource "restapi_object" "lb" {
  path         = "/v1/load_balancers"
  query_string = var.iaas_endpoint_version
  data = jsonencode({
    name            = "${var.basename}-nlb"
    is_public       = false
    is_private_path = true
    profile = {
      name = "network-private-path"
    }
    resource_group = {
      id = var.resource_group_id
    }
    subnets = [
      {
        id = var.subnet_id
      }
    ]
    pools     = []
    listeners = []
  })
  id_attribute = "id"

  lifecycle {
    ignore_changes = [
      query_string
    ]
  }
}

resource "ibm_is_lb_pool" "pool" {
  name           = "${var.basename}-pool"
  lb             = restapi_object.lb.id
  algorithm      = "round_robin"
  protocol       = "tcp"
  health_delay   = 60
  health_retries = 5
  health_timeout = 30
  health_type    = "http"
}

resource "ibm_is_lb_pool_member" "member" {
  for_each = { for index, id in var.instance_ids : index => id }

  lb        = restapi_object.lb.id
  pool      = ibm_is_lb_pool.pool.pool_id
  port      = 80
  target_id = each.value
}

resource "ibm_is_lb_listener" "listener" {
  lb       = restapi_object.lb.id
  port_min     = "80"
  port_max     = "80"
  protocol = "tcp"
  default_pool = ibm_is_lb_pool.pool.pool_id
}

# wait for LB to become active
resource "time_sleep" "wait_for_build" {
  create_duration = "2m"

  depends_on = [
    restapi_object.lb
  ]
}

data "ibm_iam_account_settings" "iam_account_settings" {
}

resource "restapi_object" "pps" {
  path         = "/v1/private_path_service_gateways"
  query_string = var.iaas_endpoint_version
  data = jsonencode({
    name = "${var.basename}-pps"
    resource_group = {
      id = var.resource_group_id
    }
    load_balancer = {
      id = restapi_object.lb.id
    }
    service_endpoints = [
      var.endpoint
    ]
    default_access_policy = "review"
  })
  id_attribute = "id"

  depends_on = [ 
    time_sleep.wait_for_build
  ]

  lifecycle {
    ignore_changes = [
      query_string
    ]
  }
}

# # to auto approve connections from the same account
# resource "restapi_object" "pps_account_policy" {
#   path         = "/v1/private_path_service_gateways/${restapi_object.pps.id}/account_policies"
#   query_string = var.iaas_endpoint_version
#   data = jsonencode({
#     account = {
#       id = data.ibm_iam_account_settings.iam_account_settings.account_id
#     }
#     access_policy = "permit"
#   })
#   id_attribute = "id"
#   lifecycle {
#     ignore_changes = [
#       query_string
#     ]
#   }
# }

output "pps" {
  value = {
    id = restapi_object.pps.api_data.id
    crn = restapi_object.pps.api_data.crn
    name= restapi_object.pps.api_data.name
    endpoint = var.endpoint
  }
}
