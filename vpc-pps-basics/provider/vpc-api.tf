data "ibm_is_image" "find_api" {
  name = "ibm-centos-stream-9-amd64-8"
}

variable "iaas_endpoint_api_maturity" {
  default = "beta"
  description = "Maturity level of the API to use as described in https://cloud.ibm.com/apidocs/vpc-beta/initial#api-versioning-beta."
}

variable "iaas_endpoint_api_version" {
  default = ""
  description = "API version to use as described in https://cloud.ibm.com/apidocs/vpc-beta/initial#api-versioning-beta. Leave empty to pick today's date."
}

locals {
  # guess the URL of the VPC API
  # split a string like https://us-south.iaas.cloud.ibm.com/ -> "https:", "", "us-south.iaas.cloud.ibm.com"
  iaas_endpoint_path_elements = split("/", data.ibm_is_image.find_api.operating_system[0].href)
  iaas_endpoint = "${local.iaas_endpoint_path_elements[0]}//${local.iaas_endpoint_path_elements[2]}"
  iaas_endpoint_api_version = var.iaas_endpoint_api_version == "" ? substr(timestamp(), 0, 10) : var.iaas_endpoint_api_version
  iaas_endpoint_version = "generation=2&maturity=${var.iaas_endpoint_api_maturity}&version=${local.iaas_endpoint_api_version}"
}
