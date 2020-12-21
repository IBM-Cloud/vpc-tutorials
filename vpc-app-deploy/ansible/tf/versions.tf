terraform {
  required_providers {
    ibm = {
      source = "IBM-Cloud/ibm"
      version = ">= 1.12.0"
    }
    null = {
      source = "hashicorp/null"
    }
  }
  required_version = ">= 0.12"
}
