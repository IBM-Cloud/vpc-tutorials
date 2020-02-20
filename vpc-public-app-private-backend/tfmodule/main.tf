data "ibm_resource_group" "all_rg" {
  name = var.resource_group_name
}

resource "ibm_is_vpc" "vpc" {
  name           = var.vpc_name == "" ? var.basename : var.vpc_name
  resource_group = data.ibm_resource_group.all_rg.id
}

resource "ibm_is_public_gateway" "backend" {
  count = var.backend_pgw ? 1 : 0
  vpc   = ibm_is_vpc.vpc.id
  name  = "${var.basename}-${var.zone}-pubgw"
  zone  = var.zone
}

resource "ibm_is_subnet" "backend" {
  name                     = "${var.basename}-backend-subnet"
  vpc                      = ibm_is_vpc.vpc.id
  zone                     = var.zone
  public_gateway           = join("", ibm_is_public_gateway.backend.*.id)
  total_ipv4_address_count = 256
  resource_group           = data.ibm_resource_group.all_rg.id
}

# bastion subnet and instance values needed by the bastion module
resource "ibm_is_subnet" "bastion" {
  name                     = "${var.basename}-bastion-subnet"
  vpc                      = ibm_is_vpc.vpc.id
  zone                     = var.zone
  total_ipv4_address_count = 256
  resource_group           = data.ibm_resource_group.all_rg.id
}

data "ibm_is_ssh_key" "sshkey" {
  name = var.ssh_key_name
}

locals {
  bastion_inress_cidr     = "0.0.0.0/0" # DANGER: cidr range that can ssh to the bastion when maintenance is enabled
  maintenance_egress_cidr = "0.0.0.0/0" # cidr range required to contact software repositories when maintenance is enabled
  frontend_ingress_cidr   = "0.0.0.0/0" # DANGER: cidr range that can access the front end service
}

module "bastion" {
  source                   = "../../vpc-secure-management-bastion-server/tfmodule"
  basename                 = var.basename
  ibm_is_vpc_id            = ibm_is_vpc.vpc.id
  ibm_is_resource_group_id = data.ibm_resource_group.all_rg.id
  zone                     = var.zone
  remote                   = local.bastion_inress_cidr
  profile                  = var.profile
  ibm_is_image_id          = var.ibm_is_image_id
  ibm_is_ssh_key_id        = data.ibm_is_ssh_key.sshkey.id
  ibm_is_subnet_id         = ibm_is_subnet.bastion.id
}

# maintenance will require ingress from the bastion, so the bastion has output a maintenance SG
# maintenance may also include installing new versions of open source software that are not in the IBM mirrors
# add the additional egress required to the maintenance security group exported by the bastion
# for example at 53 DNS, 80 http, and 443 https probably make sense
resource "ibm_is_security_group_rule" "maintenance_egress_443" {
  group     = module.bastion.security_group_id
  direction = "outbound"
  remote    = local.maintenance_egress_cidr

  tcp {
    port_min = "443"
    port_max = "443"
  }
}

resource "ibm_is_security_group_rule" "maintenance_egress_80" {
  group     = module.bastion.security_group_id
  direction = "outbound"
  remote    = "0.0.0.0/0"

  tcp {
    port_min = 80
    port_max = 80
  }
}

resource "ibm_is_security_group_rule" "maintenance_egress_53" {
  group     = module.bastion.security_group_id
  direction = "outbound"
  remote    = "0.0.0.0/0"

  tcp {
    port_min = 53
    port_max = 53
  }
}

resource "ibm_is_security_group_rule" "maintenance_egress_udp_53" {
  group     = module.bastion.security_group_id
  direction = "outbound"
  remote    = "0.0.0.0/0"

  udp {
    port_min = 53
    port_max = 53
  }
}

resource "ibm_is_subnet" "frontend" {
  name                     = "${var.basename}-frontend-subnet"
  vpc                      = ibm_is_vpc.vpc.id
  zone                     = var.zone
  total_ipv4_address_count = 256
  resource_group           = data.ibm_resource_group.all_rg.id
}

resource "ibm_is_security_group" "frontend" {
  name           = "${var.basename}-frontend-sg"
  vpc            = ibm_is_vpc.vpc.id
  resource_group = data.ibm_resource_group.all_rg.id
}

resource "ibm_is_security_group_rule" "frontend_ingress_80_all" {
  group     = ibm_is_security_group.frontend.id
  direction = "inbound"
  remote    = local.frontend_ingress_cidr

  tcp {
    port_min = 80
    port_max = 80
  }
}

resource "ibm_is_security_group_rule" "frontend_egress_tcp_port_backend" {
  group     = ibm_is_security_group.frontend.id
  direction = "outbound"
  remote    = ibm_is_security_group.backend.id

  tcp {
    port_min = var.backend_tcp_port
    port_max = var.backend_tcp_port
  }
}

resource "ibm_is_security_group" "backend" {
  name           = "${var.basename}-backend-sg"
  vpc            = ibm_is_vpc.vpc.id
  resource_group = data.ibm_resource_group.all_rg.id
}

resource "ibm_is_security_group_rule" "backend_ingress_tcp_port_frontend" {
  group     = ibm_is_security_group.backend.id
  direction = "inbound"
  remote    = ibm_is_security_group.frontend.id

  tcp {
    port_min = var.backend_tcp_port
    port_max = var.backend_tcp_port
  }
}

#Frontend
locals {
  # create either [frontend] or [frontend, maintenance] depending on the var.maintenance boolean
  frontend_security_groups = split(
    ",",
    var.maintenance ? format(
      "%s,%s",
      ibm_is_security_group.frontend.id,
      module.bastion.security_group_id,
    ) : ibm_is_security_group.frontend.id,
  )
}

resource "ibm_is_instance" "frontend" {
  name           = "${var.basename}-frontend-vsi"
  image          = var.ibm_is_image_id
  profile        = var.profile
  vpc            = ibm_is_vpc.vpc.id
  zone           = var.zone
  keys           = [data.ibm_is_ssh_key.sshkey.id]
  user_data      = var.frontend_user_data
  resource_group = data.ibm_resource_group.all_rg.id

  primary_network_interface {
    subnet = ibm_is_subnet.frontend.id
    # TF-UPGRADE-TODO: In Terraform v0.10 and earlier, it was sometimes necessary to
    # force an interpolation expression to be interpreted as a list by wrapping it
    # in an extra set of list brackets. That form was supported for compatibility in
    # v0.11, but is no longer supported in Terraform v0.12.
    #
    # If the expression in the following list itself returns a list, remove the
    # brackets to avoid interpretation as a list of lists. If the expression
    # returns a single list item then leave it as-is and remove this TODO comment.
    security_groups = flatten([local.frontend_security_groups])
  }
}

resource "ibm_is_floating_ip" "frontend" {
  name           = "${var.basename}-frontend-ip"
  target         = ibm_is_instance.frontend.primary_network_interface[0].id
  resource_group = data.ibm_resource_group.all_rg.id
}

#Backend
locals {
  # create either [backend] or [backend, maintenance] depending on the var.maintenance boolean
  backend_security_groups = split(
    ",",
    var.maintenance ? format(
      "%s,%s",
      ibm_is_security_group.backend.id,
      module.bastion.security_group_id,
    ) : ibm_is_security_group.frontend.id,
  )
}

resource "ibm_is_instance" "backend" {
  name           = "${var.basename}-backend-vsi"
  image          = var.ibm_is_image_id
  profile        = var.profile
  vpc            = ibm_is_vpc.vpc.id
  zone           = var.zone
  keys           = [data.ibm_is_ssh_key.sshkey.id]
  user_data      = var.backend_user_data
  resource_group = data.ibm_resource_group.all_rg.id

  primary_network_interface {
    subnet = ibm_is_subnet.backend.id
    # TF-UPGRADE-TODO: In Terraform v0.10 and earlier, it was sometimes necessary to
    # force an interpolation expression to be interpreted as a list by wrapping it
    # in an extra set of list brackets. That form was supported for compatibility in
    # v0.11, but is no longer supported in Terraform v0.12.
    #
    # If the expression in the following list itself returns a list, remove the
    # brackets to avoid interpretation as a list of lists. If the expression
    # returns a single list item then leave it as-is and remove this TODO comment.
    security_groups = flatten([local.backend_security_groups])
  }
}

