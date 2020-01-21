provider "ibm" {
  ibmcloud_api_key = var.ibmcloud_api_key
  region           = var.region
  generation       = var.generation
  ibmcloud_timeout = var.ibmcloud_timeout
}
