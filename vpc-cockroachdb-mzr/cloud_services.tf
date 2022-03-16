resource "ibm_resource_instance" "kp_data" {
  name              = "${var.resources_prefix}-kp-data"
  service           = "kms"
  plan              = "tiered-pricing"
  location          = var.vpc_region
  resource_group_id = data.ibm_resource_group.group.id
}

resource "ibm_kp_key" "key_protect" {
  key_protect_id = ibm_resource_instance.kp_data.guid
  key_name       = "${var.resources_prefix}-kp-data"
  standard_key   = false
  force_delete   = true

  # Addresses an issue where the volumes would go into pending_deletion 
  # if the access policy are deleted before the instance
  depends_on = [ibm_iam_authorization_policy.policy]
}

resource "ibm_iam_authorization_policy" "policy" {
  source_service_name = "server-protect"
  # source_resource_group_id = data.ibm_resource_group.group.id
  target_service_name = "kms"
  # target_resource_group_id = data.ibm_resource_group.group.id
  target_resource_instance_id = ibm_resource_instance.kp_data.guid
  roles                       = ["Reader"]
}

resource "ibm_resource_instance" "sm_certs" {
  count             = tobool(var.create_secrets_manager_instance) == true ? 1 : 0
  name              = "${var.resources_prefix}-sm-certs"
  service           = "secrets-manager"
  plan              = "lite"
  location          = var.vpc_region
  resource_group_id = data.ibm_resource_group.group.id
}

data "ibm_resource_instance" "sm_certs" {
  count             = tobool(var.create_secrets_manager_instance) == true ? 0 : 1
  name              = var.secrets_manager_instance_name
  location          = var.vpc_region
  resource_group_id = data.ibm_resource_group.group.id
  service           = "secrets-manager"
}
