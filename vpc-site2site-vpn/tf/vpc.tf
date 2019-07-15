data "ibm_resource_group" "group" {
  name = "${var.resource_group}"
}
resource ibm_is_vpc "vpc" {
  name = "${var.resources_prefix}-vpc"
  resource_group = "${data.ibm_resource_group.group.id}"
}


