# output has the "output_summary" variable - instructions to manually verify the configurtion
# other variables are ued by the automated test scripts

locals {
  hostname_postgresql = ibm_database.postgresql.connectionstrings[0].hosts[0].hostname
  postgresql_port     = ibm_database.postgresql.connectionstrings[0].hosts[0].port
  postgresql_cli      = nonsensitive(ibm_resource_key.postgresql.credentials["connection.cli.composed.0"])

  hostname_cos = local.cos_endpoint

  ip_fip_onprem                  = ibm_is_floating_ip.onprem.address
  ip_fip_bastion                 = local.bastion_ip
  ip_private_cloud               = ibm_is_instance.cloud.primary_network_interface[0].primary_ipv4_address
  ip_private_onprem              = ibm_is_instance.onprem.primary_network_interface[0].primary_ipv4_address
  ip_private_bastion             = module.bastion.instance.primary_network_interface[0].primary_ipv4_address
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

output "connectivity_verification" {
  value = <<EOT
# if the ssh key is not the default for ssh try the -I PATH_TO_PRIVATE_KEY_FILE option

#-----------------------------------
# IP and hostname variables
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

#-----------------------------------
# Test access
#-----------------------------------
# onprem VSI
ssh root@$IP_FIP_ONPREM
exit

#-----------------------------------
# cloud bastion
ssh root@$IP_FIP_BASTION
exit

#-----------------------------------
# cloud VSI through bastion
ssh -J root@$IP_FIP_BASTION root@$IP_PRIVATE_CLOUD
exit

#-----------------------------------
# cloud VSI through onprem, through the VPN tunnel, through bastion
ssh -J root@$IP_FIP_ONPREM,root@$IP_FIP_BASTION root@$IP_PRIVATE_CLOUD
exit

#-----------------------------------
# onprem VSI through bastion, through cloud VSI, through VPN tunnel
ssh -J root@$IP_FIP_BASTION,root@$IP_PRIVATE_CLOUD root@$IP_PRIVATE_ONPREM
exit

#-----------------------------------
# Test DNS resolution to postgresql and object storage through the Virtual Endpoint Gateway
#-----------------------------------
ssh root@$IP_FIP_ONPREM
HOSTNAME_POSTGRESQL=${local.hostname_postgresql}
HOSTNAME_COS=${local.hostname_cos}
# should resolve to $IP_ENDPOINT_GATEWAY_POSTGRESQL
dig $HOSTNAME_POSTGRESQL
# the telnet should display "connected" but ths is postgresql not a telent server so telnet is not going to work
telnet $HOSTNAME_POSTGRESQL ${local.postgresql_port}
# <control><c>

# Test DNS resolution to cloud object storage through the Virtual Endpoint Gateway
dig $HOSTNAME_COS
telnet $HOSTNAME_COS 443
# <control><c>
exit

#-----------------------------------
# Troubleshoot - testing is done if you had problem continue
#-----------------------------------
# the user_data/onprem.sh script is executed by cloud init, verify it worked correctly
# onprem VSI
ssh root@$IP_FIP_ONPREM

# check cloud init logs
# the last part of the log file is the execution of the user_data script, look for stuff something like this:
#+ echo onprem.sh
#onprem.sh
#+ ONPREM_IP=$IP_FIP_ONPREM
#+ ONPREM_CIDR=10.0.0.0/16
#+ GW_CLOUD_IP=52.116.133.140
#+ PRESHARED_KEY=20_PRESHARED_KEY_KEEP_SECRET_19
#+ CLOUD_CIDR=10.1.0.0/16
#+ DNS_SERVER_IP0=${local.ip_dns_server_0}
#+ DNS_SERVER_IP1=${local.ip_dns_server_1}
#+ main
vi /var/log/cloud-init-output.log

# verify these files match what was written with onprem.sh:
vi /etc/sysctl.conf
vi /etc/ipsec.secrets
vi /etc/ipsec.conf

# verify netplan, should look something like this:
#network:
#  ethernets:
#    ens3:
#      dhcp4: true
#      dhcp4-overrides:
#        use-dns: false
#      match:
#        macaddress: 02:00:16:3e:fa:c3
#      nameservers:
#        addresses:
#        - 10.1.0.5
#        - 10.1.1.5
#      set-name: ens3
#  version: 2

vi /etc/netplan/50-cloud-init.yaml

# 
#         DNS Servers: 10.1.0.5
#                      10.1.1.5
systemd-resolve --status

# The postgresql database should resolve to the address of the virtual endpoint gateway: $IP_ENDPOINT_GATEWAY_POSTGRESQL
dig $HOSTNAME_POSTGRESQL

# the ping is not going to be successful but notice the IP address displayed:
ping $HOSTNAME_POSTGRESQL

# If the IP address of postgresql is not correct, try clearing the dns caches, then wait a minute and try again
systemd-resolve --flush-caches

# The cloud-init user_data script should have upgraded netplan.io to the latest and executed: netplan apply
# verify that these commands are in the log:
vi /var/log/cloud-init-output.log

# Test DNS resolution to postgresql through the Virtual Endpoint Gateway
dig $HOSTNAME_POSTGRESQL
# the telnet should display "connected" but ths is postgresql not a telent server so telnet is not going to work
telnet $HOSTNAME_POSTGRESQL ${local.postgresql_port}
cd ~/nodejs-graphql
${local.postgresql_cli}
exit
EOT
}

output "application_deploy_test" {
  value = <<EOT
#-----------------------------------
# Configure the microservice by adding credentials and certificates
#-----------------------------------
# verify you are in the .../vpc-tutorials/sampleapps/nodejs-graphql directory
pwd
# create credentials
ibmcloud resource service-key ${ibm_resource_key.postgresql.guid} --output json > config/pg_credentials.json
ibmcloud resource service-key ${ibm_resource_key.cos.guid} --output json > config/cos_credentials.json
# create postgresql certificates
ibmcloud cdb deployment-cacert ${ibm_database.postgresql.id} -e private -c . -s

#-----------------------------------
# copy the application to the cloud and onprem VSIs
#-----------------------------------
scp -J root@$IP_FIP_BASTION -r ../sampleapps/nodejs-graphql root@$IP_PRIVATE_CLOUD:
scp -r ../sampleapps/nodejs-graphql root@$IP_FIP_ONPREM:

#-----------------------------------
# run microservice on the cloud VSI
#-----------------------------------
ssh -J root@$IP_FIP_BASTION root@$IP_PRIVATE_CLOUD
cd nodejs-graphql
npm install
npm run build
# copy and optionally touch up a little (not required)
cp config/config.template.json config/config.json
node ./build/createTables.js
node ./build/createBucket.js
# notice the unique bucket name
vi config/config.json; # change the bucketName
# start the application
npm start

#-----------------------------------
# Test the microservice from the onprem VSI (over the VPN), on a different terminal
#-----------------------------------
IP_FIP_ONPREM=${local.ip_fip_onprem}
ssh root@$IP_FIP_ONPREM
IP_PRIVATE_CLOUD=${local.ip_private_cloud}
# exect empty array from postgresql
curl -X POST -H "Content-Type: application/json" --data '{ "query": "query read_database { read_database { id balance transactiontime } }" }' http://$IP_PRIVATE_CLOUD/api/bank
# expect empty array from object storage
curl -X POST -H "Content-Type: application/json" --data '{ "query": "query read_items { read_items { key size modified } }" }' http://$IP_PRIVATE_CLOUD/api/bank
# add a record to postgresql and object storage
curl -X POST -H "Content-Type: application/json" --data '{ "query": "mutation add_to_database_and_storage_bucket { add(balance: 10, item_content: \"Payment for movie, popcorn and drink...\") { id status } }" }' http://$IP_PRIVATE_CLOUD/api/bank
# read the records in postgresql and object storage
curl -X POST -H "Content-Type: application/json" --data '{ "query": "query read_database_and_items { read_database { id balance transactiontime } read_items { key size modified } }" }' http://$IP_PRIVATE_CLOUD/api/bank

# test access to postgresql over the private endpoint gateway
cd ~/nodejs-graphql
${local.postgresql_cli}
exit

#-----------------------------------
# Back in the cloud VSI terminal session
#-----------------------------------
# <control><c>
exit

EOT
}