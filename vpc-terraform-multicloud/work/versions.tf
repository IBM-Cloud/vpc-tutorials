terraform {
  required_providers {
    ibm = {
      source  = "IBM-Cloud/ibm"
      version = ">= 1.12.0"
    }
    aws = {
      source = "hashicorp/aws"
    }
  }
  required_version = ">= 0.12"
}
