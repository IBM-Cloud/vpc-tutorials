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
}

resource "ibm_iam_authorization_policy" "policy" {
  source_service_name = "server-protect"
  source_resource_group_id = data.ibm_resource_group.group.id
  target_service_name = "kms"
  target_resource_group_id = data.ibm_resource_group.group.id
  roles               = ["Reader"]
}

resource "ibm_resource_instance" "cm_certs" {
  name              = "${var.resources_prefix}-cm-certs"
  service           = "cloudcerts"
  plan              = "free"
  location          = var.vpc_region
  resource_group_id = data.ibm_resource_group.group.id
}

resource "ibm_certificate_manager_import" "cert" {
  count = 3

  certificate_manager_instance_id = ibm_resource_instance.cm_certs.id
  name                            = element(ibm_is_instance.vsi_database.*.primary_network_interface.0.primary_ipv4_address, count.index)
  description                     = ""

  data = {
    content      = file("config/${var.resources_prefix}-certs/${element(ibm_is_instance.vsi_database.*.primary_network_interface.0.primary_ipv4_address, count.index)}.node.crt")
    priv_key     = file("config/${var.resources_prefix}-certs/${element(ibm_is_instance.vsi_database.*.primary_network_interface.0.primary_ipv4_address, count.index)}.node.key")
    
    # Terraform does not support running plan if local file does not exist yet, unable to handle setting intermediate to `file("config/ca.crt)`, setting to blank value for now. 
    intermediate = ""
  }

  depends_on = [null_resource.vsi_admin]

}
