data "ibm_is_ssh_key" "sshkey" {
  name = var.ssh_keyname
}

data "ibm_is_image" "image" {
  name = "ibm-ubuntu-22-04-1-minimal-amd64-3"
}

data "ibm_resource_group" "group" {
  name = var.resource_group_name
}

resource "ibm_is_vpc" "vpc" {
  name           = var.vpc_name
  resource_group = data.ibm_resource_group.group.id
}

resource "ibm_is_subnet" "subnet" {
  count                    = 2
  name                     = "${var.vpc_name}-subnet-${count.index + 1}"
  vpc                      = ibm_is_vpc.vpc.id
  zone                     = "${var.region}-${count.index + 1}"
  resource_group           = data.ibm_resource_group.group.id
  total_ipv4_address_count = "256"
}

resource "ibm_is_security_group" "autoscale_security_group" {
  name           = "${var.basename}-autoscale-sg"
  vpc            = ibm_is_vpc.vpc.id
  resource_group = data.ibm_resource_group.group.id
}

resource "ibm_is_security_group" "maintenance_security_group" {
  name           = "${var.basename}-maintenance-sg"
  vpc            = ibm_is_vpc.vpc.id
  resource_group = data.ibm_resource_group.group.id
}

resource "ibm_is_security_group" "lb_security_group" {
  name           = "${var.basename}-lb-sg"
  vpc            = ibm_is_vpc.vpc.id
  resource_group = data.ibm_resource_group.group.id
}

resource "ibm_is_security_group_rule" "autoscale_security_group_rule_icmp" {
  group     = ibm_is_security_group.autoscale_security_group.id
  direction = "inbound"
  remote    = "0.0.0.0/0"
  icmp {
    type = 8
  }
}

resource "ibm_is_security_group_rule" "autoscale_security_group_rule_tcp_22" {
  group     = ibm_is_security_group.autoscale_security_group.id
  direction = "inbound"
  remote    = "0.0.0.0/0"
  tcp {
    port_min = 22
    port_max = 22
  }
}

resource "ibm_is_security_group_rule" "autoscale_security_group_rule_tcp_80" {
  group     = ibm_is_security_group.autoscale_security_group.id
  direction = "inbound"
  remote    = ibm_is_security_group.lb_security_group.id
  tcp {
    port_min = 80
    port_max = 80
  }
}

resource "ibm_is_security_group_rule" "autoscale_security_group_rule_tcp_443" {
  group     = ibm_is_security_group.autoscale_security_group.id
  direction = "inbound"
  remote    = ibm_is_security_group.lb_security_group.id
  tcp {
    port_min = 443
    port_max = 443
  }
}

resource "ibm_is_security_group_rule" "autoscale_security_group_rule_tcp_outbound" {
  group     = ibm_is_security_group.autoscale_security_group.id
  direction = "outbound"
  remote    = ibm_is_security_group.maintenance_security_group.id
  tcp {
    port_min = 22
    port_max = 22
  }
}

resource "ibm_is_security_group_rule" "maintenance_security_group_rule_tcp_22" {
  group     = ibm_is_security_group.maintenance_security_group.id
  direction = "inbound"
  remote    = ibm_is_security_group.autoscale_security_group.id
  tcp {
    port_min = 22
    port_max = 22
  }
}

resource "ibm_is_security_group_rule" "maintenance_security_group_rule_tcp_outbound_80" {
  group     = ibm_is_security_group.maintenance_security_group.id
  direction = "outbound"
  remote    = "0.0.0.0/0"
  tcp {
    port_min = 80
    port_max = 80
  }
}

resource "ibm_is_security_group_rule" "maintenance_security_group_rule_tcp_outbound_443" {
  group     = ibm_is_security_group.maintenance_security_group.id
  direction = "outbound"
  remote    = "0.0.0.0/0"
  tcp {
    port_min = 443
    port_max = 443
  }
}


resource "ibm_is_security_group_rule" "maintenance_security_group_rule_tcp_outbound" {
  group     = ibm_is_security_group.maintenance_security_group.id
  direction = "outbound"
  remote    = "0.0.0.0/0"
  tcp {
    port_min = 53
    port_max = 53
  }
}

resource "ibm_is_security_group_rule" "maintenance_security_group_rule_udp_outbound" {
  group     = ibm_is_security_group.maintenance_security_group.id
  direction = "outbound"
  remote    = "0.0.0.0/0"
  udp {
    port_min = 53
    port_max = 53
  }
}

resource "ibm_is_security_group_rule" "lb_security_group_rule_tcp_80" {
  group     = ibm_is_security_group.lb_security_group.id
  direction = "inbound"
  remote    = "0.0.0.0/0"
  tcp {
    port_min = 80
    port_max = 80
  }
}

resource "ibm_is_security_group_rule" "lb_security_group_rule_tcp_443" {
  group     = ibm_is_security_group.lb_security_group.id
  direction = "inbound"
  remote    = "0.0.0.0/0"
  tcp {
    port_min = 443
    port_max = 443
  }
}

resource "ibm_is_security_group_rule" "lb_security_group_rule_tcp_80_outbound" {
  group     = ibm_is_security_group.lb_security_group.id
  direction = "outbound"
  remote    = ibm_is_security_group.autoscale_security_group.id
  tcp {
    port_min = 80
    port_max = 80
  }
}

resource "ibm_is_security_group_rule" "lb_security_group_rule_tcp_443_outbound" {
  group     = ibm_is_security_group.lb_security_group.id
  direction = "outbound"
  remote    = ibm_is_security_group.autoscale_security_group.id
  tcp {
    port_min = 443
    port_max = 443
  }
}

resource "ibm_is_lb" "lb" {
  name            = "${var.vpc_name}-lb"
  subnets         = ibm_is_subnet.subnet.*.id
  resource_group  = data.ibm_resource_group.group.id
  security_groups = [ibm_is_security_group.lb_security_group.id]
}

resource "ibm_is_lb_pool" "lb-pool" {
  lb                 = ibm_is_lb.lb.id
  name               = "${var.vpc_name}-lb-pool"
  protocol           = var.enable_end_to_end_encryption ? "https" : "http"
  algorithm          = "round_robin"
  health_delay       = "15"
  health_retries     = "2"
  health_timeout     = "5"
  health_type        = var.enable_end_to_end_encryption ? "https" : "http"
  health_monitor_url = "/"
  depends_on         = [time_sleep.wait_30_seconds]
}

resource "ibm_is_lb_listener" "lb-listener" {
  lb                   = ibm_is_lb.lb.id
  port                 = var.certificate_crn == "" ? "80" : "443"
  protocol             = var.certificate_crn == "" ? "http" : "https"
  default_pool         = element(split("/", ibm_is_lb_pool.lb-pool.id), 1)
  certificate_instance = var.certificate_crn == "" ? "" : var.certificate_crn
}

resource "ibm_is_instance_template" "instance_template" {
  name           = "${var.basename}-instance-template"
  image          = data.ibm_is_image.image.id
  profile        = "cx2-2x4"
  resource_group = data.ibm_resource_group.group.id

  primary_network_interface {
    subnet          = ibm_is_subnet.subnet[0].id
    security_groups = [ibm_is_security_group.autoscale_security_group.id, ibm_is_security_group.maintenance_security_group.id]
  }

  vpc       = ibm_is_vpc.vpc.id
  zone      = "${var.region}-1"
  keys      = [data.ibm_is_ssh_key.sshkey.id]
  user_data = var.enable_end_to_end_encryption ? file("./scripts/install-software-ssl.sh") : file("./scripts/install-software.sh")
}

resource "ibm_is_instance_group" "instance_group" {
  name               = "${var.basename}-instance-group"
  instance_template  = ibm_is_instance_template.instance_template.id
  instance_count     = 1
  subnets            = ibm_is_subnet.subnet.*.id
  load_balancer      = ibm_is_lb.lb.id
  load_balancer_pool = element(split("/", ibm_is_lb_pool.lb-pool.id), 1)
  application_port   = var.enable_end_to_end_encryption ? 443 : 80
  resource_group     = data.ibm_resource_group.group.id

  depends_on = [ibm_is_lb_listener.lb-listener, ibm_is_lb_pool.lb-pool, ibm_is_lb.lb]
}

resource "ibm_is_instance_group_manager" "instance_group_manager" {
  name                 = "${var.basename}-instance-group-manager"
  aggregation_window   = 90
  instance_group       = ibm_is_instance_group.instance_group.id
  cooldown             = 120
  manager_type         = "autoscale"
  enable_manager       = true
  max_membership_count = 5
}

resource "ibm_is_instance_group_manager_policy" "cpuPolicy" {
  instance_group         = ibm_is_instance_group.instance_group.id
  instance_group_manager = ibm_is_instance_group_manager.instance_group_manager.manager_id
  metric_type            = "cpu"
  metric_value           = 10
  policy_type            = "target"
  name                   = "${var.basename}-instance-group-manager-policy"
}

resource "time_sleep" "wait_30_seconds" {
  depends_on = [ibm_is_lb.lb]

  destroy_duration = "30s"
}


output "LOAD_BALANCER_HOSTNAME" {
  value = ibm_is_lb.lb.hostname
}
