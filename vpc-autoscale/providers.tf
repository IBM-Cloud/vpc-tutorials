provider "ibm" {
  ibmcloud_api_key = var.ibmcloud_api_key
  region           = var.region
  generation       = 2
  ibmcloud_timeout = var.ibmcloud_timeout
}
