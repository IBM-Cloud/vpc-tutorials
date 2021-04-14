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
  depends_on = [ ibm_iam_authorization_policy.policy ]
}

resource "ibm_iam_authorization_policy" "policy" {
  source_service_name = "server-protect"
  # source_resource_group_id = data.ibm_resource_group.group.id
  target_service_name = "kms"
  # target_resource_group_id = data.ibm_resource_group.group.id
  target_resource_instance_id = ibm_resource_instance.kp_data.guid
  roles                       = ["Reader"]
}

resource "ibm_resource_instance" "cm_certs" {
  name              = "${var.resources_prefix}-cm-certs"
  service           = "cloudcerts"
  plan              = "free"
  location          = var.vpc_region
  resource_group_id = data.ibm_resource_group.group.id
}