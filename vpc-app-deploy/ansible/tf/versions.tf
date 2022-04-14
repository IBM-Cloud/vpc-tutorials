terraform {
  required_providers {
    ibm = {
      source  = "IBM-Cloud/ibm"
      version = ">= 1.40.1"
    }
    null = {
      source = "hashicorp/null"
    }
  }
  required_version = ">= 1.1.8"
}
