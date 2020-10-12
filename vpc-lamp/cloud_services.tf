resource "ibm_resource_instance" "kp_data" {
  count = tobool(var.byok_data_volume) == true ? 1 : 0

  name              = "${var.resources_prefix}-kp-data"
  service           = "kms"
  plan              = "tiered-pricing"
  location          = var.vpc_region
  resource_group_id = data.ibm_resource_group.group.id
}

resource "ibm_kp_key" "key_protect" {
  count = tobool(var.byok_data_volume) == true ? 1 : 0

  key_protect_id = ibm_resource_instance.kp_data[0].guid
  key_name       = "${var.resources_prefix}-kp-data"
  standard_key   = false
}

resource "ibm_iam_authorization_policy" "policy" {
  count = tobool(var.byok_data_volume) == true ? 1 : 0

  source_service_name         = "server-protect"
  # source_resource_group_id    = data.ibm_resource_group.group.id
  target_service_name         = "kms"
  # target_resource_group_id = data.ibm_resource_group.group.id
  target_resource_instance_id = ibm_resource_instance.kp_data.0.guid
  roles                       = ["Reader"]
}
