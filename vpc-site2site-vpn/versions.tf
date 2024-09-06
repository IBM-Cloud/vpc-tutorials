# versions

terraform {
  required_providers {
    ibm = {
      source  = "IBM-Cloud/ibm"
      version = ">= 1.68.1"
    }
  }
  required_version = ">= 1.9.0"
}
