variable "name" {}
variable "tags" {}
variable "resource_group_id" {}
variable "region" {}
variable "zones_to_cidrs" {}

locals {
  zones = keys(var.zones_to_cidrs)
  cidrs = values(var.zones_to_cidrs)
  tags = concat(var.tags, ["vpc"])
}
