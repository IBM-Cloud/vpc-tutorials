#!/bin/bash


# https://{region}.certificate-manager.cloud.ibm.com/api
# ibmcloud resource service-instance {instance_name} --output JSON

# 1. ibmcloud iam oauth-tokens
# 2. read id from config.json
# 3. curl -H "Authorization: Bearer <IAM-token>" https://<api-endpoint>/api/v3/<URL encoded CRN-based instanceId>/certificates/
# 4. curl -X POST -H "Content-Type: application/json" -H "authorization: Bearer <IAM-token>" -d "{ "name":"<name>", "description":"<description>", "data":{ "content": "<certificate>", "priv_key": "<privateKey>", "intermediate": "<intermediate>" } }" https://<api-endpoint>/api/v3/<URL encoded CRN-based instanceId>/certificates/import
# 5. curl -H "Authorization: Bearer <IAM-token>" https://<api-endpoint>/api/v2/certificate/<URL encoded CRN-based certificateId>
# 6. curl -X DELETE -H "Authorization: Bearer <IAM-token>" https://<api-endpoint>/api/v2/certificate/<URL encoded CRN-based certificateId>

function importCert {
  local certificate
  local privateKey
  local intermediate
  local authorization

  iam_oauth_tokens=$(ibmcloud iam oauth-tokens --output json)
  [ $? -ne 0 ] && log_error "${FUNCNAME[0]}: Error reading iam oauth-tokens ${iam_oauth_tokens}." && return 1

  iam_token=$(echo "$iam_oauth_tokens" | jq -r '.iam_token')

  cm_uri=${region}.certificate-manager.cloud.ibm.com
  cm_crn=$(jq -r '.service_instances[]? | select(.service_name == "cloudcerts") | .crn' ${configFile} | tr -d '\r\n' | curl -Gso /dev/null -w %{url_effective} --data-urlencode @- "" | cut -c 3-)

  certificate=$(cat "${config_template_file_dir}/local/${vsi_ipv4_address}.node.crt" | jq -Rsr 'tojson')
  privateKey=$(cat "${config_template_file_dir}/local/${vsi_ipv4_address}.node.key" | jq -Rsr 'tojson')
  intermediate=$(cat "${config_template_file_dir}/local/ca.crt" | jq -Rsr 'tojson')

cat > "${config_template_file_dir}/local/${vsi_ipv4_address}.cert.json" <<- EOF
{ 
  "name": $vsi_ipv4_address, 
  "description": "", 
  "data": 
  { 
    "content": $certificate, 
    "priv_key": $privateKey, 
    "intermediate": $intermediate 
  } 
}
EOF

  curl -X POST -H "Content-Type: application/json" -H "authorization: ${iam_token}" -d @${config_template_file_dir}/local/${vsi_ipv4_address}.cert.json "https://${cm_uri}/api/v3/${cm_crn}/certificates/import"

}