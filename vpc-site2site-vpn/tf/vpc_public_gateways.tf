resource "ibm_is_public_gateway" "pgw" {
  count = "3"
  name  = "${var.resources_prefix}-pgw-${count.index + 1}"
  vpc   = "${ibm_is_vpc.vpc.id}"
  zone  = "${lookup(var.vpc_zones, "${var.vpc_region}-availability-zone-${count.index + 1}")}"
}
