# onprem_config are the variables required to configure the onprem VPN server that come from the cloud environment

locals {
  GW_CLOUD_IP    = ibm_is_vpn_gateway.cloud.public_ip_address != "0.0.0.0" ? ibm_is_vpn_gateway.cloud.public_ip_address : ibm_is_vpn_gateway.cloud.public_ip_address2
  DNS_SERVER_IP0 = tolist(ibm_dns_custom_resolver.location.locations)[0].dns_server_ip
  DNS_SERVER_IP1 = tolist(ibm_dns_custom_resolver.location.locations)[1].dns_server_ip
}
