data ibm_is_image "image_name" {
  name = "${var.vpc_image_name}"
}

data ibm_is_ssh_key "ssh_key" {
  count = "${length(var.vpc_ssh_keys)}"
  name  = "${var.vpc_ssh_keys[count.index]}"
}

resource ibm_is_instance "vsi_cloud" {
  count = 1
  name  = "${var.resources_prefix}-cloud-vsi"
  vpc   = "${ibm_is_vpc.vpc.id}"
  zone  = "${lookup(var.vpc_zones, "${var.vpc_region}-availability-zone-2")}"
  keys           = ["${data.ibm_is_ssh_key.ssh_key.*.id}"]
  image          = "${data.ibm_is_image.image_name.id}"
  profile        = "${var.vpc_image_profile}"
  resource_group = "${data.ibm_resource_group.group.id}"

  primary_network_interface = {
    subnet          = "${ibm_is_subnet.sub_cloud.0.id}"
    security_groups = ["${ibm_is_security_group.sg_cloud.id}", "${module.vpc_bastion.sg_maintenance_id}"]
  }
}
