resource "ibm_is_subnet" "sub_app" {
  count                    = 3
  name                     = "${var.resources_prefix}-sub-app-${count.index + 1}"
  vpc                      = ibm_is_vpc.vpc.id
  zone                     = "${var.vpc_region}-${count.index + 1}"
  total_ipv4_address_count = 16
  public_gateway           = element(ibm_is_public_gateway.pgw.*.id, count.index)
  resource_group           = data.ibm_resource_group.group.id
}

resource "ibm_is_security_group" "sg_app" {
  name           = "${var.resources_prefix}-sg-app"
  vpc            = ibm_is_vpc.vpc.id
  resource_group = data.ibm_resource_group.group.id
}

resource "ibm_is_security_group_rule" "sg_app_inbound_tcp_80" {
  group     = ibm_is_security_group.sg_app.id
  direction = "inbound"
  remote    = "0.0.0.0/0"

  tcp {
    port_min = 80
    port_max = 80
  }
}

resource "ibm_is_security_group_rule" "sg_app_outbound_tcp_26257" {
  count     = 3
  group     = ibm_is_security_group.sg_app.id
  direction = "outbound"
  remote    = element(ibm_is_subnet.sub_database.*.ipv4_cidr_block, count.index)

  tcp {
    port_min = 26257
    port_max = 26257
  }
}

data "ibm_is_image" "app_image_name" {
  name = var.vpc_app_image_name
}

resource "ibm_is_instance" "vsi_app" {
  count          = 3
  name           = "${var.resources_prefix}-vsi-app-${count.index + 1}"
  vpc            = ibm_is_vpc.vpc.id
  zone           = "${var.vpc_region}-${count.index + 1}"
  keys           = var.ssh_private_key_format == "build" ? concat(data.ibm_is_ssh_key.ssh_key.*.id, [ibm_is_ssh_key.build_key.0.id]) : data.ibm_is_ssh_key.ssh_key.*.id
  image          = data.ibm_is_image.app_image_name.id
  profile        = var.vpc_app_image_profile
  resource_group = data.ibm_resource_group.group.id

  primary_network_interface {
    subnet          = element(ibm_is_subnet.sub_app.*.id, count.index)
    security_groups = [ibm_is_security_group.sg_app.id, ibm_is_security_group.sg_maintenance.id]
  }

  depends_on = [
    ibm_is_security_group_rule.sg_app_inbound_tcp_80,
    ibm_is_security_group_rule.sg_app_outbound_tcp_26257
  ]
}

resource "ibm_is_security_group" "lb_public_sg" {
  name           = "${var.resources_prefix}-lb-public-sg"
  vpc            = ibm_is_vpc.vpc.id
  resource_group = data.ibm_resource_group.group.id
}

resource "ibm_is_security_group_rule" "lb_public_sg_rule_tcp_80" {
  group     = ibm_is_security_group.lb_public_sg.id
  direction = "inbound"
  remote    = "0.0.0.0/0"
  tcp {
    port_min = 80
    port_max = 80
  }
}

resource "ibm_is_security_group_rule" "lb_public_sg_rule_tcp_outbound_80" {
  group     = ibm_is_security_group.lb_public_sg.id
  direction = "outbound"
  remote    = "0.0.0.0/0"
  tcp {
    port_min = 80
    port_max = 80
  }
}

resource "ibm_is_lb" "lb_public" {
  name            = "${var.resources_prefix}-lb-public"
  type            = "public"
  subnets         = ibm_is_subnet.sub_app.*.id
  resource_group  = data.ibm_resource_group.group.id
  security_groups = [ibm_is_security_group.lb_public_sg.id]
}

resource "ibm_is_lb_pool" "app_pool" {
  name               = "app"
  lb                 = ibm_is_lb.lb_public.id
  algorithm          = "round_robin"
  protocol           = "http"
  health_delay       = 60
  health_retries     = 5
  health_timeout     = 2
  health_type        = "http"
  health_monitor_url = "/health"
}

resource "ibm_is_lb_listener" "app_listener" {
  lb           = ibm_is_lb.lb_public.id
  default_pool = element(split("/", ibm_is_lb_pool.app_pool.id), 1)
  port         = 80
  protocol     = "http"
}

resource "ibm_is_lb_pool_member" "app_pool_members" {
  count = 3
  lb    = ibm_is_lb.lb_public.id
  pool  = element(split("/", ibm_is_lb_pool.app_pool.id), 1)
  port  = 80
  target_address = element(
    ibm_is_instance.vsi_app.*.primary_network_interface.0.primary_ip.address,
    count.index,
  )
}

resource "null_resource" "vsi_app" {
  count = 3

  connection {
    type = "ssh"
    host = element(
      ibm_is_instance.vsi_app.*.primary_network_interface.0.primary_ip.address,
      count.index,
    )
    user         = "root"
    private_key = var.ssh_private_key_format == "file" ? file(var.ssh_private_key_file) : var.ssh_private_key_format == "content" ? var.ssh_private_key_content : tls_private_key.build_key.0.private_key_pem
    bastion_host = ibm_is_floating_ip.vpc_vsi_admin_fip[0].address
  }

  provisioner "file" {
    content = templatefile("${path.module}/scripts/app-deploy.sh", {
      vsi_ipv4_address = element(
        ibm_is_instance.vsi_app.*.primary_network_interface.0.primary_ip.address,
        count.index,
      )
      floating_ip   = ibm_is_floating_ip.vpc_vsi_admin_fip[0].address
      lb_hostname   = ibm_is_lb.lb_private.hostname
      app_url       = "https://github.com/IBM-Cloud/vpc-tutorials.git"
      app_repo      = "vpc-tutorials"
      app_directory = "sampleapps/nodejs-graphql"
    })
    destination = "/tmp/app-deploy.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "cloud-init status --wait",
      "chmod +x /tmp/app-deploy.sh",
      "sed -i.bak 's/\r//g' /tmp/app-deploy.sh",
      "/tmp/app-deploy.sh",
    ]
  }

  depends_on = [null_resource.vsi_admin]
}

resource "null_resource" "vsi_app_2" {
  count = 3

  connection {
    type = "ssh"
    host = element(
      ibm_is_instance.vsi_app.*.primary_network_interface.0.primary_ip.address,
      count.index,
    )
    user         = "root"
    private_key = var.ssh_private_key_format == "file" ? file(var.ssh_private_key_file) : var.ssh_private_key_format == "content" ? var.ssh_private_key_content : tls_private_key.build_key.0.private_key_pem
    bastion_host = ibm_is_floating_ip.vpc_vsi_admin_fip[0].address
  }

  provisioner "remote-exec" {
    inline = [
      "cd /vpc-tutorials/sampleapps/nodejs-graphql/",
      "pm2 start build/index.js",
      "pm2 startup systemd",
      "pm2 save",
    ]
  }

  depends_on = [null_resource.vsi_admin_application_init]
}