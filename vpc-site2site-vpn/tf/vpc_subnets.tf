resource ibm_is_subnet "sub_cloud" {
  count                    = 1
  name                     = "${var.resources_prefix}-cloud-subnet-${count.index + 1}"
  vpc                      = "${ibm_is_vpc.vpc.id}"
  zone                     = "${lookup(var.vpc_zones, "${var.vpc_region}-availability-zone-2")}"
  total_ipv4_address_count = 16
  public_gateway           = "${element(ibm_is_public_gateway.pgw.*.id, 1)}"
}