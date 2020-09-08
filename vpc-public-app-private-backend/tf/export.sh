# see https://cloud.ibm.com/docs/terraform?topic=terraform-getting-started to follow the instructions to get 
# terraform installed and how to get the api key

# pq
export TF_VAR_ibmcloud_api_key=wn29AL5furBSfH3wiaX0vkLNSUFC7rMLEWYpVtyZaS9E
# p001
export TF_VAR_ibmcloud_api_key=YnuPzvW8D4vF2NAeOJba8TP47Xw1B0ZmgbmmoK9Ib5K7
# p000
export TF_VAR_ibmcloud_api_key=PWltZRD2vmib-RfFcCcaNfcMi2MJrJq1q6G2lRxovFro

export TF_VAR_vpc_import=1
export TF_VAR_prefix="p000"
export TF_VAR_ssh_key_name=$TF_VAR_prefix
export TF_VAR_resource_group_name=lab0
export TF_VAR_generation=2
