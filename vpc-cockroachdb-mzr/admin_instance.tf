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
  count     = 3
  group     = ibm_is_security_group.sg_admin.id
  direction = "outbound"
  remote    = element(ibm_is_subnet.sub_database.*.ipv4_cidr_block, count.index)

  tcp {
    port_min = 26257
    port_max = 26257
  }
}

resource "ibm_is_security_group_rule" "sg_admin_outbound_tcp_8080" {
  count     = 3
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
  count                    = 1
  name                     = "${var.resources_prefix}-sub-admin-1"
  vpc                      = ibm_is_vpc.vpc.id
  zone                     = "${var.vpc_region}-${count.index + 1}"
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
  zone           = "${var.vpc_region}-${count.index + 1}"
  keys           = var.ssh_private_key_format == "build" ? concat(data.ibm_is_ssh_key.ssh_key.*.id, [ibm_is_ssh_key.build_key.0.id]) : data.ibm_is_ssh_key.ssh_key.*.id
  image          = data.ibm_is_image.admin_image_name.id
  profile        = var.vpc_admin_image_profile
  resource_group = data.ibm_resource_group.group.id

  primary_network_interface {
    subnet          = element(ibm_is_subnet.sub_admin.*.id, count.index)
    security_groups = [ibm_is_security_group.sg_admin.id, ibm_is_security_group.sg_maintenance.id]
  }

  depends_on = [
    ibm_is_security_group_rule.sg_admin_inbound_tcp_22,
    ibm_is_security_group_rule.sg_admin_outbound_tcp_22,
    ibm_is_security_group_rule.sg_admin_outbound_tcp_26257,
    ibm_is_security_group_rule.sg_admin_outbound_tcp_8080,
    ibm_is_security_group_rule.sg_maintenance_inbound_tcp_22,
    ibm_is_security_group_rule.sg_maintenance_outbound_iaas_endpoints,
    ibm_is_security_group_rule.sg_maintenance_outbound_tcp_53,
    ibm_is_security_group_rule.sg_maintenance_outbound_udp_53,
    ibm_is_security_group_rule.sg_maintenance_outbound_tcp_443,
    ibm_is_security_group_rule.sg_maintenance_outbound_tcp_80
  ]
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
    content = templatefile("${path.module}/scripts/cockroachdb-admin-systemd.sh", {
      lb_hostname = ibm_is_lb.lb_private.hostname
      db_node1_address = element(
        ibm_is_instance.vsi_database.*.primary_network_interface.0.primary_ipv4_address,
        0,
      )
      db_node2_address = element(
        ibm_is_instance.vsi_database.*.primary_network_interface.0.primary_ipv4_address,
        1,
      )
      db_node3_address = element(
        ibm_is_instance.vsi_database.*.primary_network_interface.0.primary_ipv4_address,
        2,
      )
      app_node1_address = element(
        ibm_is_instance.vsi_app.*.primary_network_interface.0.primary_ipv4_address,
        0,
      )
      app_node2_address = element(
        ibm_is_instance.vsi_app.*.primary_network_interface.0.primary_ipv4_address,
        1,
      )
      app_node3_address = element(
        ibm_is_instance.vsi_app.*.primary_network_interface.0.primary_ipv4_address,
        2,
      )
      app_url            = var.cockroachdb_binary_url
      app_binary_archive = var.cockroachdb_binary_archive
      app_binary         = "cockroach"
      app_user           = "cockroach"
      app_directory      = var.cockroachdb_binary_directory
      certs_directory    = "/certs"
      ca_directory       = "/cas"
      ibmcloud_api_key   = var.ibmcloud_api_key
      region             = var.vpc_region
      resource_group_id  = data.ibm_resource_group.group.id
      cm_instance_id     = ibm_resource_instance.cm_certs.id
    })
    destination = "/tmp/cockroachdb-admin-systemd.sh"
  }

  provisioner "file" {
    source      = "scripts/ssh-config.txt"
    destination = ".ssh/config"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod 400 ~/.ssh/config",
      "echo '${tls_private_key.build_key.0.private_key_pem}' > ~/.ssh/id_rsa",
      "chmod 600 ~/.ssh/id_rsa",
      "sed -i.bak 's/\r//g' ~/.ssh/id_rsa",
      "chmod +x /tmp/cockroachdb-admin-systemd.sh",
      "sed -i.bak 's/\r//g' /tmp/cockroachdb-admin-systemd.sh",
      "/tmp/cockroachdb-admin-systemd.sh",
    ]
  }

}

resource "null_resource" "vsi_admin_database_init" {
  count = 1

  connection {
    type        = "ssh"
    host        = ibm_is_floating_ip.vpc_vsi_admin_fip[0].address
    user        = "root"
    private_key = var.ssh_private_key_format == "file" ? file(var.ssh_private_key_file) : var.ssh_private_key_format == "content" ? var.ssh_private_key_content : tls_private_key.build_key.0.private_key_pem
  }

  provisioner "file" {
    content = templatefile("${path.module}/scripts/cockroachdb-admin-database.sh", {
      db_node1_address = element(
        ibm_is_instance.vsi_database.*.primary_network_interface.0.primary_ipv4_address,
        0,
      )
      db_node2_address = element(
        ibm_is_instance.vsi_database.*.primary_network_interface.0.primary_ipv4_address,
        1,
      )
      db_node3_address = element(
        ibm_is_instance.vsi_database.*.primary_network_interface.0.primary_ipv4_address,
        2,
      )
      certs_directory = "/certs"
    })
    destination = "/tmp/cockroachdb-admin-database.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/cockroachdb-admin-database.sh",
      "sed -i.bak 's/\r//g' /tmp/cockroachdb-admin-database.sh",
      "/tmp/cockroachdb-admin-database.sh",
    ]
  }

  depends_on = [null_resource.vsi_database]
}

resource "null_resource" "vsi_admin_database_init_2" {
  count = 1

  connection {
    type        = "ssh"
    host        = ibm_is_floating_ip.vpc_vsi_admin_fip[0].address
    user        = "root"
    private_key = var.ssh_private_key_format == "file" ? file(var.ssh_private_key_file) : var.ssh_private_key_format == "content" ? var.ssh_private_key_content : tls_private_key.build_key.0.private_key_pem
  }

  provisioner "remote-exec" {
    inline = [
      "cockroach init --certs-dir=/certs --host=${element(
        ibm_is_instance.vsi_database.*.primary_network_interface.0.primary_ipv4_address,
        0,
      )}",
    ]
  }

  depends_on = [null_resource.vsi_database_2]
}

resource "null_resource" "vsi_admin_application_init" {
  count = 1

  connection {
    type        = "ssh"
    host        = ibm_is_floating_ip.vpc_vsi_admin_fip[0].address
    user        = "root"
    private_key = var.ssh_private_key_format == "file" ? file(var.ssh_private_key_file) : var.ssh_private_key_format == "content" ? var.ssh_private_key_content : tls_private_key.build_key.0.private_key_pem
  }

  provisioner "file" {
    content = templatefile("${path.module}/scripts/cockroachdb-admin-application.sh", {
      app_node1_address = element(
        ibm_is_instance.vsi_app.*.primary_network_interface.0.primary_ipv4_address,
        0,
      )
      app_node2_address = element(
        ibm_is_instance.vsi_app.*.primary_network_interface.0.primary_ipv4_address,
        1,
      )
      app_node3_address = element(
        ibm_is_instance.vsi_app.*.primary_network_interface.0.primary_ipv4_address,
        2,
      )
      certs_directory = "/certs"
    })
    destination = "/tmp/cockroachdb-admin-application.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/cockroachdb-admin-application.sh",
      "sed -i.bak 's/\r//g' /tmp/cockroachdb-admin-application.sh",
      "/tmp/cockroachdb-admin-application.sh",
    ]
  }

  depends_on = [null_resource.vsi_app]
}
