# versions

terraform {
  required_providers {
    ibm = {
      source  = "IBM-Cloud/ibm"
      // todo >=
      version = "= 1.40.1"
    }
  }
  required_version = ">= 1.1.5"
}
