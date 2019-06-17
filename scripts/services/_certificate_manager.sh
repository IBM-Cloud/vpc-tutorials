#!/bin/bash

function importCert {
  local certificate
  local privateKey
  local intermediate
  local authorization

  log_info "${FUNCNAME[0]}: Running ibmcloud iam oauth-tokens --output json"
  iam_oauth_tokens=$(ibmcloud iam oauth-tokens --output json)
  [ $? -ne 0 ] && log_error "${FUNCNAME[0]}: Error reading iam oauth-tokens." && log_error "${iam_oauth_tokens}" && return 1

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