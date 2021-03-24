provider "ibm" {
  ibmcloud_api_key = var.ibmcloud_api_key
  ibmcloud_timeout = 300
  generation       = 2
  region           = var.vpc_region
}
