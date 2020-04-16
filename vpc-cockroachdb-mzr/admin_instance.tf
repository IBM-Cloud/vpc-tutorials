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

resource "ibm_is_security_group_rule" "sg_admin_outbound_tcp_22" {
  group     = ibm_is_security_group.sg_admin.id
  direction = "outbound"
  remote    = ibm_is_security_group.sg_maintenance.id

  tcp {
    port_min = 22
    port_max = 22
  }
}

resource "ibm_is_security_group_rule" "sg_admin_outbound_tcp_26257" {
  count     = "3"
  group     = ibm_is_security_group.sg_admin.id
  direction = "outbound"
  remote    = element(ibm_is_subnet.sub_database.*.ipv4_cidr_block, count.index)

  tcp {
    port_min = 26257
    port_max = 26257
  }
}

resource "ibm_is_security_group_rule" "sg_admin_outbound_tcp_8080" {
  count     = "3"
  group     = ibm_is_security_group.sg_admin.id
  direction = "outbound"
  remote    = element(ibm_is_subnet.sub_database.*.ipv4_cidr_block, count.index)

  tcp {
    port_min = 8080
    port_max = 8080
  }
}

resource "ibm_is_security_group" "sg_maintenance" {
  name           = "${var.resources_prefix}-sg-maintenance"
  vpc            = ibm_is_vpc.vpc.id
  resource_group = data.ibm_resource_group.group.id
}

resource "ibm_is_security_group_rule" "sg_maintenance_inbound_tcp_22" {
  group     = ibm_is_security_group.sg_maintenance.id
  direction = "inbound"
  remote    = ibm_is_security_group.sg_admin.id

  tcp {
    port_min = 22
    port_max = 22
  }
}

resource "ibm_is_security_group_rule" "sg_maintenance_outbound_iaas_endpoints" {
  group     = ibm_is_security_group.sg_maintenance.id
  direction = "outbound"
  remote    = "161.26.0.0/16"
}

resource "ibm_is_security_group_rule" "sg_maintenance_outbound_tcp_53" {
  group     = ibm_is_security_group.sg_maintenance.id
  direction = "outbound"
  remote    = "0.0.0.0/0"

  tcp {
    port_min = 53
    port_max = 53
  }
}

resource "ibm_is_security_group_rule" "sg_maintenance_outbound_udp_53" {
  group     = ibm_is_security_group.sg_maintenance.id
  direction = "outbound"
  remote    = "0.0.0.0/0"

  udp {
    port_min = 53
    port_max = 53
  }
}

resource "ibm_is_security_group_rule" "sg_maintenance_outbound_tcp_443" {
  group     = ibm_is_security_group.sg_maintenance.id
  direction = "outbound"
  remote    = "0.0.0.0/0"

  tcp {
    port_min = 443
    port_max = 443
  }
}

resource "ibm_is_security_group_rule" "sg_maintenance_outbound_tcp_80" {
  group     = ibm_is_security_group.sg_maintenance.id
  direction = "outbound"
  remote    = "0.0.0.0/0"

  tcp {
    port_min = 80
    port_max = 80
  }
}

resource "ibm_is_subnet" "sub_admin" {
  count                    = "1"
  name                     = "${var.resources_prefix}-sub-admin-1"
  vpc                      = ibm_is_vpc.vpc.id
  zone                     = var.vpc_zones["${var.vpc_region}-availability-zone-${count.index + 1}"]
  total_ipv4_address_count = 16
  public_gateway           = ibm_is_public_gateway.pgw[0].id
  resource_group           = data.ibm_resource_group.group.id
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
    security_groups = [ibm_is_security_group.sg_admin.id, ibm_is_security_group.sg_maintenance.id]
  }
}

resource "ibm_is_floating_ip" "vpc_vsi_admin_fip" {
  count          = 1
  name           = "${var.resources_prefix}-vsi-admin-fip"
  target         = ibm_is_instance.vpc_vsi_admin[0].primary_network_interface[0].id
  resource_group = data.ibm_resource_group.group.id
}

data "template_file" "cockroachdb_admin_systemd" {
  count    = 1
  template = file("./scripts/cockroachdb-admin-systemd.sh")

  vars = {
    lb_hostname = ibm_is_lb.lb_private.hostname
    node1_address = element(
      ibm_is_instance.vsi_database.*.primary_network_interface.0.primary_ipv4_address,
      0,
    )
    node2_address = element(
      ibm_is_instance.vsi_database.*.primary_network_interface.0.primary_ipv4_address,
      1,
    )
    node3_address = element(
      ibm_is_instance.vsi_database.*.primary_network_interface.0.primary_ipv4_address,
      2,
    )
    app_url            = "https://binaries.cockroachdb.com"
    app_binary_archive = "cockroach-v19.2.6.linux-amd64.tgz"
    app_binary         = "cockroach"
    app_user           = "cockroach"
    app_directory      = "cockroach-v19.2.6.linux-amd64"
    certs_directory    = "/certs"
    ca_directory       = "/cas"
  }
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
    content = element(
      data.template_file.cockroachdb_admin_systemd.*.rendered,
      count.index,
    )
    destination = "/tmp/cockroachdb-admin-systemd.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/cockroachdb-admin-systemd.sh",
      "/tmp/cockroachdb-admin-systemd.sh",
    ]
  }

  provisioner "local-exec" {
    command     = "mkdir -p ./config/${var.resources_prefix}-certs/"
    interpreter = ["bash", "-c"]
  }

  provisioner "local-exec" {
    command     = "scp -F ./scripts/ssh.config -i ${var.ssh_private_key} -r root@${ibm_is_floating_ip.vpc_vsi_admin_fip[0].address}:/certs/* ./config/${var.resources_prefix}-certs/"
    interpreter = ["bash", "-c"]
  }

  provisioner "local-exec" {
    when        = destroy
    command     = "rm -rf ./config/${var.resources_prefix}-certs"
    interpreter = ["bash", "-c"]
  }
}

resource "null_resource" "vsi_admin_database_init" {
  count = 1

  connection {
    type        = "ssh"
    host        = ibm_is_floating_ip.vpc_vsi_admin_fip[0].address
    user        = "root"
    private_key = var.ssh_private_key_format == "file" ? file(var.ssh_private_key) : var.ssh_private_key
  }

  provisioner "remote-exec" {
    inline = [
      "cockroach init --certs-dir=/certs --host=${element(
        ibm_is_instance.vsi_database.*.primary_network_interface.0.primary_ipv4_address,
        0,
      )}",
    ]
  }

  depends_on = [null_resource.vsi_database]
}

