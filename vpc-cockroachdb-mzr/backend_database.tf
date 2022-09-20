resource "ibm_is_subnet" "sub_database" {
  count                    = 3
  name                     = "${var.resources_prefix}-sub-database-${count.index + 1}"
  vpc                      = ibm_is_vpc.vpc.id
  zone                     = "${var.vpc_region}-${count.index + 1}"
  total_ipv4_address_count = 16
  public_gateway           = element(ibm_is_public_gateway.pgw.*.id, count.index)
  resource_group           = data.ibm_resource_group.group.id
}

resource "ibm_is_security_group" "sg_database" {
  name           = "${var.resources_prefix}-sg-database"
  vpc            = ibm_is_vpc.vpc.id
  resource_group = data.ibm_resource_group.group.id
}

resource "ibm_is_security_group_rule" "sg_database_inbound_tcp_26257" {
  count     = 3
  group     = ibm_is_security_group.sg_database.id
  direction = "inbound"
  remote    = element(ibm_is_subnet.sub_database.*.ipv4_cidr_block, count.index)

  tcp {
    port_min = 26257
    port_max = 26257
  }
}

resource "ibm_is_security_group_rule" "sg_database_admin_inbound_tcp_26257" {
  count     = 1
  group     = ibm_is_security_group.sg_database.id
  direction = "inbound"
  remote    = ibm_is_subnet.sub_admin[0].ipv4_cidr_block

  tcp {
    port_min = 26257
    port_max = 26257
  }
}

resource "ibm_is_security_group_rule" "sg_database_inbound_tcp_8080" {
  count     = 3
  group     = ibm_is_security_group.sg_database.id
  direction = "inbound"
  remote    = element(ibm_is_subnet.sub_database.*.ipv4_cidr_block, count.index)

  tcp {
    port_min = 8080
    port_max = 8080
  }
}

resource "ibm_is_security_group_rule" "sg_database_admin_inbound_tcp_8080" {
  count     = 1
  group     = ibm_is_security_group.sg_database.id
  direction = "inbound"
  remote    = ibm_is_subnet.sub_admin[0].ipv4_cidr_block

  tcp {
    port_min = 8080
    port_max = 8080
  }
}

resource "ibm_is_security_group_rule" "sg_database_outbound_tcp_26257" {
  count     = 3
  group     = ibm_is_security_group.sg_database.id
  direction = "outbound"
  remote    = element(ibm_is_subnet.sub_database.*.ipv4_cidr_block, count.index)

  tcp {
    port_min = 26257
    port_max = 26257
  }
}

resource "ibm_is_security_group_rule" "sg_database_outbound_tcp_8080" {
  count     = 3
  group     = ibm_is_security_group.sg_database.id
  direction = "outbound"
  remote    = element(ibm_is_subnet.sub_database.*.ipv4_cidr_block, count.index)

  tcp {
    port_min = 8080
    port_max = 8080
  }
}

resource "ibm_is_volume" "vsi_database_volume" {
  count          = 3
  name           = "${var.resources_prefix}-data-${count.index + 1}"
  profile        = "custom"
  zone           = "${var.vpc_region}-${count.index + 1}"
  iops           = 6000
  capacity       = 100
  resource_group = data.ibm_resource_group.group.id

  encryption_key = ibm_kp_key.key_protect.crn
}

data "ibm_is_image" "database_image_name" {
  name = var.vpc_database_image_name
}

resource "ibm_is_instance" "vsi_database" {
  count          = 3
  name           = "${var.resources_prefix}-vsi-database-${count.index + 1}"
  vpc            = ibm_is_vpc.vpc.id
  zone           = "${var.vpc_region}-${count.index + 1}"
  keys           = var.ssh_private_key_format == "build" ? concat(data.ibm_is_ssh_key.ssh_key.*.id, [ibm_is_ssh_key.build_key.0.id]) : data.ibm_is_ssh_key.ssh_key.*.id
  image          = data.ibm_is_image.database_image_name.id
  profile        = var.vpc_database_image_profile
  resource_group = data.ibm_resource_group.group.id

  primary_network_interface {
    subnet          = element(ibm_is_subnet.sub_database.*.id, count.index)
    security_groups = [ibm_is_security_group.sg_database.id, ibm_is_security_group.sg_maintenance.id]
  }

  volumes = [element(ibm_is_volume.vsi_database_volume.*.id, count.index)]

  depends_on = [ 
    ibm_is_security_group_rule.sg_database_inbound_tcp_26257,
    ibm_is_security_group_rule.sg_database_admin_inbound_tcp_26257,
    ibm_is_security_group_rule.sg_database_inbound_tcp_8080,
    ibm_is_security_group_rule.sg_database_admin_inbound_tcp_8080,
    ibm_is_security_group_rule.sg_database_outbound_tcp_26257,
    ibm_is_security_group_rule.sg_database_outbound_tcp_8080
  ]
}

resource "ibm_is_security_group" "lb_private_sg" {
  name           = "${var.resources_prefix}-lb-private-sg"
  vpc            = ibm_is_vpc.vpc.id
  resource_group = data.ibm_resource_group.group.id
}

resource "ibm_is_security_group_rule" "lb_private_sg_rule_tcp_inbound_26257" {
  count     = 3
  group     = ibm_is_security_group.lb_private_sg.id
  direction = "inbound"
  remote    = element(ibm_is_subnet.sub_app.*.ipv4_cidr_block, count.index)

  tcp {
    port_min = 26257
    port_max = 26257
  }
}

resource "ibm_is_security_group_rule" "lb_private_sg_rule_tcp_outbound_26257" {
  count     = 3
  group     = ibm_is_security_group.lb_private_sg.id
  direction = "outbound"
  remote    = element(ibm_is_subnet.sub_database.*.ipv4_cidr_block, count.index)

  tcp {
    port_min = 26257
    port_max = 26257
  }
}

resource "ibm_is_security_group_rule" "lb_private_sg_rule_tcp_outbound_8080" {
  count     = 3
  group     = ibm_is_security_group.lb_private_sg.id
  direction = "outbound"
  remote    = element(ibm_is_subnet.sub_database.*.ipv4_cidr_block, count.index)

  tcp {
    port_min = 8080
    port_max = 8080
  }
}

resource "ibm_is_lb" "lb_private" {
  name           = "${var.resources_prefix}-lb-private"
  type           = "private"
  subnets        = ibm_is_subnet.sub_database.*.id
  resource_group = data.ibm_resource_group.group.id
  security_groups = [ibm_is_security_group.lb_private_sg.id]
}

resource "ibm_is_lb_pool" "database_pool" {
  name           = "database"
  lb             = ibm_is_lb.lb_private.id
  algorithm      = "round_robin"
  protocol       = "tcp"
  health_delay   = 60
  health_retries = 5
  health_timeout = 2

  health_type         = "http"
  health_monitor_url  = "/health?ready=1"
  health_monitor_port = 8080
}

resource "ibm_is_lb_listener" "database_listener" {
  lb           = ibm_is_lb.lb_private.id
  default_pool = element(split("/", ibm_is_lb_pool.database_pool.id), 1)
  port         = 26257
  protocol     = "tcp"
}

resource "ibm_is_lb_pool_member" "database_pool_members" {
  count = 3
  lb    = ibm_is_lb.lb_private.id
  pool  = element(split("/", ibm_is_lb_pool.database_pool.id), 1)
  port  = 26257
  target_address = element(
    ibm_is_instance.vsi_database.*.primary_network_interface.0.primary_ip.address,
    count.index,
  )
}

resource "null_resource" "vsi_database" {
  count = 3

  connection {
    type = "ssh"
    host = element(
      ibm_is_instance.vsi_database.*.primary_network_interface.0.primary_ip.address,
      count.index,
    )
    user         = "root"
    private_key = var.ssh_private_key_format == "file" ? file(var.ssh_private_key_file) : var.ssh_private_key_format == "content" ? var.ssh_private_key_content : tls_private_key.build_key.0.private_key_pem
    bastion_host = ibm_is_floating_ip.vpc_vsi_admin_fip[0].address
  }

  provisioner "file" {
    content = templatefile("${path.module}/scripts/cockroachdb-basic-systemd.sh", {
        vsi_ipv4_address = element(
          ibm_is_instance.vsi_database.*.primary_network_interface.0.primary_ip.address,
          count.index,
        )
        floating_ip = ibm_is_floating_ip.vpc_vsi_admin_fip[0].address
        join_list = join(
          ",",
          ibm_is_instance.vsi_database.*.primary_network_interface.0.primary_ip.address,
        )
        app_url            = var.cockroachdb_binary_url
        app_binary_archive = var.cockroachdb_binary_archive
        app_binary         = "cockroach"
        app_user           = "cockroach"
        app_directory      = var.cockroachdb_binary_directory
        certs_directory       = "certs"
        ca_directory          = "cas"
        store_directory       = "/data/cockroach"
        store_certs_directory = "/data/certs"
    })
    destination = "/tmp/cockroachdb-basic-systemd.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "cloud-init status --wait",
      "chmod +x /tmp/cockroachdb-basic-systemd.sh",
      "sed -i.bak 's/\r//g' /tmp/cockroachdb-basic-systemd.sh",
      "/tmp/cockroachdb-basic-systemd.sh",
    ]
  }

  depends_on = [null_resource.vsi_admin]
}

resource "null_resource" "vsi_database_2" {
  count = 3

  connection {
    type = "ssh"
    host = element(
      ibm_is_instance.vsi_database.*.primary_network_interface.0.primary_ip.address,
      count.index,
    )
    user         = "root"
    private_key = var.ssh_private_key_format == "file" ? file(var.ssh_private_key_file) : var.ssh_private_key_format == "content" ? var.ssh_private_key_content : tls_private_key.build_key.0.private_key_pem
    bastion_host = ibm_is_floating_ip.vpc_vsi_admin_fip[0].address
  }

  provisioner "remote-exec" {
    inline = [
      "chown -R cockroach /data/certs",
      "chmod 700 /data/certs/*",
      "systemctl start cockroachdb",
    ]
  }

  depends_on = [null_resource.vsi_admin_database_init]
}