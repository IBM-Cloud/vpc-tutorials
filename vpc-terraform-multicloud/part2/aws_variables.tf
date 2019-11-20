# AWS configuration
variable aws_region {
  default = "us-west-2"
}

variable aws_zones {
  default = [
    "us-west-2a",
    "us-west-2b",
    "us-west-2c",
  ]
}
variable aws_ssh_key_name {}
variable aws_access_key_id {}
variable aws_secret_access_key {}
