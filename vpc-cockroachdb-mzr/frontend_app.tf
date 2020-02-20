resource "ibm_is_subnet" "sub_app" {
  count                    = "3"
  name                     = "${var.resources_prefix}-sub-app-${count.index + 1}"
  vpc                      = ibm_is_vpc.vpc.id
  zone                     = var.vpc_zones["${var.vpc_region}-availability-zone-${count.index + 1}"]
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
  count     = "3"
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
  zone           = var.vpc_zones["${var.vpc_region}-availability-zone-${count.index + 1}"]
  keys           = data.ibm_is_ssh_key.ssh_key.*.id
  image          = data.ibm_is_image.app_image_name.id
  profile        = var.vpc_app_image_profile
  resource_group = data.ibm_resource_group.group.id

  primary_network_interface {
    subnet          = element(ibm_is_subnet.sub_app.*.id, count.index)
    security_groups = [ibm_is_security_group.sg_app.id, ibm_is_security_group.sg_maintenance.id]
  }
}

resource "ibm_is_lb" "lb_public" {
  name           = "${var.resources_prefix}-lb-public"
  type           = "public"
  subnets        = ibm_is_subnet.sub_app.*.id
  resource_group = data.ibm_resource_group.group.id
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
    ibm_is_instance.vsi_app.*.primary_network_interface.0.primary_ipv4_address,
    count.index,
  )
}

data "template_file" "app_deploy" {
  count    = 3
  template = file("./scripts/app-deploy.sh")

  vars = {
    vsi_ipv4_address = element(
      ibm_is_instance.vsi_app.*.primary_network_interface.0.primary_ipv4_address,
      count.index,
    )
    floating_ip   = ibm_is_floating_ip.vpc_vsi_admin_fip[0].address
    lb_hostname   = ibm_is_lb.lb_private.hostname
    app_url       = "https://github.com/IBM-Cloud/vpc-tutorials.git"
    app_repo      = "vpc-tutorials"
    app_directory = "sampleapps/nodejs-graphql"
  }
}

resource "null_resource" "vsi_app" {
  count = 3

  connection {
    type = "ssh"
    host = element(
      ibm_is_instance.vsi_app.*.primary_network_interface.0.primary_ipv4_address,
      count.index,
    )
    user         = "root"
    private_key  = var.ssh_private_key_format == "file" ? file(var.ssh_private_key) : var.ssh_private_key
    bastion_host = ibm_is_floating_ip.vpc_vsi_admin_fip[0].address
  }

  provisioner "file" {
    content     = element(data.template_file.app_deploy.*.rendered, count.index)
    destination = "/tmp/app-deploy.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "cloud-init status --wait",
      "chmod +x /tmp/app-deploy.sh",
      "/tmp/app-deploy.sh",
      "mkdir -p /vpc-tutorials/sampleapps/nodejs-graphql/certs",
    ]
  }

  provisioner "local-exec" {
    command = "scp -F ./scripts/ssh.config -i ${var.ssh_private_key} -o 'ProxyJump root@${ibm_is_floating_ip.vpc_vsi_admin_fip[0].address}' config/${var.resources_prefix}-certs/client.maxroach.key root@${element(
      ibm_is_instance.vsi_app.*.primary_network_interface.0.primary_ipv4_address,
      count.index,
    )}:/vpc-tutorials/sampleapps/nodejs-graphql/certs/client.maxroach.key"
    interpreter = ["bash", "-c"]
  }

  provisioner "local-exec" {
    command = "scp -F ./scripts/ssh.config -i ${var.ssh_private_key} -o 'ProxyJump root@${ibm_is_floating_ip.vpc_vsi_admin_fip[0].address}' config/${var.resources_prefix}-certs/client.maxroach.crt root@${element(
      ibm_is_instance.vsi_app.*.primary_network_interface.0.primary_ipv4_address,
      count.index,
    )}:/vpc-tutorials/sampleapps/nodejs-graphql/certs/client.maxroach.crt"
    interpreter = ["bash", "-c"]
  }

  provisioner "local-exec" {
    command = "scp -F ./scripts/ssh.config -i ${var.ssh_private_key} -o 'ProxyJump root@${ibm_is_floating_ip.vpc_vsi_admin_fip[0].address}' config/${var.resources_prefix}-certs/ca.crt root@${element(
      ibm_is_instance.vsi_app.*.primary_network_interface.0.primary_ipv4_address,
      count.index,
    )}:/vpc-tutorials/sampleapps/nodejs-graphql/certs/ca.crt"
    interpreter = ["bash", "-c"]
  }

  provisioner "remote-exec" {
    inline = [
      "cd /vpc-tutorials/sampleapps/nodejs-graphql/",
      "pm2 start build/index.js",
      "pm2 startup systemd",
      "pm2 save",
    ]
  }

  depends_on = [null_resource.vsi_admin]
}

