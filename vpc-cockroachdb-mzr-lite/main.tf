provider "ibm" {
  ibmcloud_api_key = var.ibmcloud_api_key
  ibmcloud_timeout = 300
  generation       = var.generation
  region           = var.vpc_region
}

data "ibm_resource_group" "group" {
  name = var.resource_group
}

resource "ibm_is_vpc" "vpc" {
  name           = "${var.resources_prefix}-vpc"
  resource_group = data.ibm_resource_group.group.id
}

data "ibm_is_ssh_key" "ssh_key" {
  count = length(var.vpc_ssh_keys)
  name  = var.vpc_ssh_keys[count.index]
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
  keys           = data.ibm_is_ssh_key.ssh_key.*.id
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
    private_key = var.ssh_private_key_format == "file" ? file(var.ssh_private_key) : var.ssh_private_key
  }

  provisioner "file" {
    source = "readme.md"
    destination = "/tmp/readme.md"
  }

  provisioner "local-exec" {
    command     = "mkdir -p ~/.ssh; echo '${var.ssh_private_key}' > ~/.ssh/id_rsa_schematics; chmod 600 ~/.ssh/id_rsa_schematics; sed -i.bak 's/\r//g' id_rsa_schematics; ls -latr ~/.ssh"
    interpreter = ["bash", "-c"]
  }

  provisioner "local-exec" {
    command     = "scp -F ./scripts/ssh-config.txt -i '~/.ssh/id_rsa_schematics' -r root@${ibm_is_floating_ip.vpc_vsi_admin_fip[0].address}:/tmp/readme.md ./readme_remote.md"
    interpreter = ["bash", "-c"]
  }

}