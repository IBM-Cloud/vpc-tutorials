# output has the "output_summary" variable - instructions to manually verify the configurtion
# other variables are ued by the automated test scripts

locals {
  hostname_postgresql = nonsensitive(ibm_resource_key.postgresql.credentials["connection.postgres.hosts.0.hostname"])
  postgresql_port     = nonsensitive(ibm_resource_key.postgresql.credentials["connection.postgres.hosts.0.port"])
  postgresql_cli      = nonsensitive(ibm_resource_key.postgresql.credentials["connection.cli.composed.0"])

  hostname_cos = local.cos_endpoint

  ip_fip_onprem                  = ibm_is_floating_ip.onprem.address
  ip_fip_bastion                 = local.bastion_ip
  ip_private_cloud               = ibm_is_instance.cloud.primary_network_interface[0].primary_ip.0.address
  ip_private_onprem              = ibm_is_instance.onprem.primary_network_interface[0].primary_ip.0.address
  ip_private_bastion             = module.bastion.instance.primary_network_interface[0].primary_ip.0.address
  ip_dns_server_0                = local.DNS_SERVER_IP0
  ip_dns_server_1                = local.DNS_SERVER_IP1
  ip_endpoint_gateway_postgresql = ibm_is_virtual_endpoint_gateway.postgresql.ips[0].address
  ip_endpoint_gateway_cos        = ibm_is_virtual_endpoint_gateway.cos.ips[0].address
}
output "hostname_postgresql" {
  value = local.hostname_postgresql
}
output "hostname_cos" {
  value = local.hostname_cos
}
output "ip_fip_bastion" {
  value = local.ip_fip_bastion
}
output "ip_fip_onprem" {
  value = local.ip_fip_onprem
}
output "ip_private_cloud" {
  value = local.ip_private_cloud
}
output "ip_private_onprem" {
  value = local.ip_private_onprem
}
output "ip_private_bastion" {
  value = local.ip_private_bastion
}
output "ip_endpoint_gateway_postgresql" {
  value = local.ip_endpoint_gateway_postgresql
}
output "ip_endpoint_gateway_cos" {
  value = local.ip_endpoint_gateway_cos
}
output "ip_dns_server_0" {
  value = local.ip_dns_server_0
}
output "ip_dns_server_1" {
  value = local.ip_dns_server_1
}

output "environment_variables" {
  value = <<-EOT
  #-----------------------------------
  # Variables from the cloud resources created
  #-----------------------------------
  IP_FIP_ONPREM=${local.ip_fip_onprem}
  IP_PRIVATE_ONPREM=${local.ip_private_onprem}
  IP_PRIVATE_CLOUD=${local.ip_private_cloud}
  IP_FIP_BASTION=${local.ip_fip_bastion}
  IP_PRIVATE_BASTION=${local.ip_private_bastion}
  IP_DNS_SERVER_0=${local.ip_dns_server_0}
  IP_DNS_SERVER_1=${local.ip_dns_server_1}
  IP_ENDPOINT_GATEWAY_POSTGRESQL=${local.ip_endpoint_gateway_postgresql}
  IP_ENDPOINT_GATEWAY_COS=${local.ip_endpoint_gateway_cos}
  HOSTNAME_POSTGRESQL=${local.hostname_postgresql}
  HOSTNAME_COS=${local.hostname_cos}
  PORT_POSTGRESQL=${local.postgresql_port}
EOT
}
output "application_variables" {
  value = <<-EOT
  RESOURCE_GROUP_NAME=${var.resource_group_name}
  REGION=${var.region}
  GUID_POSTGRESQL=${ibm_resource_key.postgresql.guid}
  GUID_COS=${ibm_resource_key.cos.guid}
  CRN_POSTGRESQL=${ibm_database.postgresql.id}
  POSTGRESQL_CLI="${local.postgresql_cli}"
EOT
}
