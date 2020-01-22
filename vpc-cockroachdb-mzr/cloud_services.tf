resource "ibm_resource_instance" "kp_data" {
  name              = "${var.resources_prefix}-kp-data"
  service           = "kms"
  plan              = "tiered-pricing"
  location          = var.vpc_region
  resource_group_id = data.ibm_resource_group.group.id

  provisioner "local-exec" {
    when        = destroy
    command     = "sh config/key-protect-delete.sh"
    interpreter = ["bash", "-c"]
  }

  provisioner "local-exec" {
    when        = destroy
    command     = "> config/key-protect-delete.sh"
    interpreter = ["bash", "-c"]
  }
}

data "external" "key_protect" {
  program = ["bash", "./scripts/key-protect-external.sh"]

  query = {
    config_directory    = "config"
    service_instance_id = element(split(":", ibm_resource_instance.kp_data.id), 7)
    key_name            = "${var.resources_prefix}-kp-data"
    region              = var.vpc_region
    resource_group_id   = data.ibm_resource_group.group.id
    ibmcloud_api_key    = var.ibmcloud_api_key
  }
}

resource "ibm_resource_instance" "cm_certs" {
  name              = "${var.resources_prefix}-cm-certs"
  service           = "cloudcerts"
  plan              = "free"
  location          = var.vpc_region
  resource_group_id = data.ibm_resource_group.group.id
}

data "external" "certificate_manager" {
  count = 3

  program = ["bash", "./scripts/certificate-manager-external.sh"]

  query = {
    config_directory = "config/${var.resources_prefix}-certs"
    region           = var.vpc_region
    cm_instance_id   = ibm_resource_instance.cm_certs.id
    vsi_ipv4_address = element(
      ibm_is_instance.vsi_database.*.primary_network_interface.0.primary_ipv4_address,
      count.index,
    )
    resource_group_id = data.ibm_resource_group.group.id
    ibmcloud_api_key  = var.ibmcloud_api_key
  }
}

