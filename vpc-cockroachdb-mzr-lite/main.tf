provider "ibm" {
  ibmcloud_api_key = var.ibmcloud_api_key
  ibmcloud_timeout = 300
  generation       = var.generation
  region           = var.vpc_region
}

data "ibm_resource_group" "group" {
  name = var.resource_group
}

#Create a ssh keypair which will be used to provision code onto the system - and also access the VM for debug if needed.
resource "tls_private_key" "build_key" {
  count = var.ssh_private_key_format == "build" ? 1 : 0
  algorithm = "RSA"
  rsa_bits = "4096"
}

resource "ibm_is_ssh_key" "build_key" {
  count = var.ssh_private_key_format == "build" ? 1 : 0
  name = "${var.resources_prefix}-build-key"
  public_key = tls_private_key.build_key.0.public_key_openssh
}

data "ibm_is_ssh_key" "ssh_key" {
  count = length(var.vpc_ssh_keys)
  name  = var.vpc_ssh_keys[count.index]
}

resource "ibm_is_vpc" "vpc" {
  name           = "${var.resources_prefix}-vpc"
  resource_group = data.ibm_resource_group.group.id
}

resource "ibm_is_subnet" "sub_admin" {
  count                    = "1"
  name                     = "${var.resources_prefix}-sub-admin-1"
  vpc                      = ibm_is_vpc.vpc.id
  zone                     = var.vpc_zones["${var.vpc_region}-availability-zone-${count.index + 1}"]
  total_ipv4_address_count = 16
  resource_group           = data.ibm_resource_group.group.id
}

resource "ibm_is_security_group" "sg_admin" {
  name           = "${var.resources_prefix}-sg-admin"
  vpc            = ibm_is_vpc.vpc.id
  resource_group = data.ibm_resource_group.group.id
}

resource "ibm_is_security_group_rule" "sg_admin_inbound_tcp_22" {
  group     = ibm_is_security_group.sg_admin.id
  direction = "inbound"
  remote    = "0.0.0.0/0"

  tcp {
    port_min = 22
    port_max = 22
  }
}

data "ibm_is_image" "admin_image_name" {
  name = var.vpc_admin_image_name
}

resource "ibm_is_instance" "vpc_vsi_admin" {
  count          = 1
  name           = "${var.resources_prefix}-vsi-admin"
  vpc            = ibm_is_vpc.vpc.id
  zone           = var.vpc_zones["${var.vpc_region}-availability-zone-${count.index + 1}"]
  keys           = var.ssh_private_key_format == "build" ? concat(data.ibm_is_ssh_key.ssh_key.*.id, [ibm_is_ssh_key.build_key.0.id]) : data.ibm_is_ssh_key.ssh_key.*.id
  image          = data.ibm_is_image.admin_image_name.id
  profile        = var.vpc_admin_image_profile
  resource_group = data.ibm_resource_group.group.id

  primary_network_interface {
    subnet          = element(ibm_is_subnet.sub_admin.*.id, count.index)
    security_groups = [ibm_is_security_group.sg_admin.id]
  }
}

resource "ibm_is_floating_ip" "vpc_vsi_admin_fip" {
  count          = 1
  name           = "${var.resources_prefix}-vsi-admin-fip"
  target         = ibm_is_instance.vpc_vsi_admin[0].primary_network_interface[0].id
  resource_group = data.ibm_resource_group.group.id
}

resource "null_resource" "vsi_admin" {
  count = 1

  connection {
    type        = "ssh"
    host        = ibm_is_floating_ip.vpc_vsi_admin_fip[0].address
    user        = "root"
    private_key = var.ssh_private_key_format == "file" ? file(var.ssh_private_key_file) : var.ssh_private_key_format == "content" ? var.ssh_private_key_content : tls_private_key.build_key.0.private_key_pem
  }

  provisioner "file" {
    source = "readme.md"
    destination = "/tmp/readme.md"
  }

}