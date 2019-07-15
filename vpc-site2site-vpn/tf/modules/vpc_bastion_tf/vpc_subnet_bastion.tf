resource ibm_is_subnet "sub_bastion" {
  count                    = "1"
  name                     = "${var.vpc_subnet_name}"
  vpc                      = "${var.vpc_id}"
  zone                     = "${lookup(var.vpc_zones, "${var.vpc_region}-availability-zone-${count.index + 1}")}"
  total_ipv4_address_count = 16
  public_gateway           = "${var.vpc_public_gateway_id}"
}
