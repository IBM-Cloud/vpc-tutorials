provider "ibm" {
  version = "~> 0.17"
  ibmcloud_api_key   = "${var.ibmcloud_api_key}"
  generation         = "${var.generation}"
  region             = "${var.vpc_region}"
  softlayer_username = "${var.softlayer_username}"
  softlayer_api_key  = "${var.softlayer_api_key}"
}

provider "null" {
  version = "~> 2.1"
}

provider "template" {
  version = "~> 2.1"
}