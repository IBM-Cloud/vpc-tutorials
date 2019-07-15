data ibm_is_image "image_name" {
  name = "${var.vpc_vsi_image_name}"
}

resource ibm_is_instance "vpc_vsi_bastion" {
  count = 1
  name  = "${var.vpc_vsi_name}"
  vpc   = "${var.vpc_id}"
  zone  = "${lookup(var.vpc_zones, "${var.vpc_region}-availability-zone-${count.index + 1}")}"
  keys           = ["${data.ibm_is_ssh_key.ssh_key.*.id}"]
  image          = "${data.ibm_is_image.image_name.id}"
  profile        = "${var.vpc_vsi_image_profile}"
  resource_group = "${var.vpc_resource_group_id}"

  primary_network_interface = {
    subnet          = "${element(ibm_is_subnet.sub_bastion.*.id, count.index)}"
    security_groups = ["${ibm_is_security_group.sg_bastion.id}"]
  }
}

resource ibm_is_floating_ip "vpc_vsi_bastion_fip" {
  count = 1
  name   = "${var.vpc_vsi_fip_name}"
  target = "${ibm_is_instance.vpc_vsi_bastion.primary_network_interface.0.id}"
}