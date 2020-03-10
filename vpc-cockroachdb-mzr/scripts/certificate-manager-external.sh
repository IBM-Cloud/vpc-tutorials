#!/bin/bash
eval "$(jq -r '@sh "ibmcloud_api_key=\(.ibmcloud_api_key) region=\(.region) resource_group_id=\(.resource_group_id) cm_instance_id=\(.cm_instance_id) config_directory=\(.config_directory) vsi_ipv4_address=\(.vsi_ipv4_address)"')"

ibmcloud login --apikey ${ibmcloud_api_key} -r ${region} -g ${resource_group_id} 2>&1 >/dev/null
[ $? -ne 0 ] && exit 1

iam_oauth_tokens=$(ibmcloud iam oauth-tokens --output json)
[ $? -ne 0 ] && exit 1

iam_token=$(echo "${iam_oauth_tokens}" | jq -r '.iam_token')

cm_uri=${region}.certificate-manager.cloud.ibm.com
cm_crn=$(echo ${cm_instance_id} | tr -d '\n' | curl -Gso /dev/null -w %{url_effective} --data-urlencode @- "" | cut -c 3-)

certificate=$(cat "${config_directory}/${vsi_ipv4_address}.node.crt" | jq -Rsr 'tojson')
privateKey=$(cat "${config_directory}/${vsi_ipv4_address}.node.key" | jq -Rsr 'tojson')
intermediate=$(cat "${config_directory}/ca.crt" | jq -Rsr 'tojson')

cat > "${config_directory}/${vsi_ipv4_address}.cert.json" <<- EOF
{ 
  "name": "${vsi_ipv4_address}", 
  "description": "", 
  "data": 
  { 
    "content": ${certificate}, 
    "priv_key": ${privateKey}, 
    "intermediate": ${intermediate} 
  } 
}
EOF

curl -s -X POST -H "Content-Type: application/json" -H "authorization: ${iam_token}" -d @${config_directory}/${vsi_ipv4_address}.cert.json "https://${cm_uri}/api/v3/${cm_crn}/certificates/import" 2>&1 >/dev/null

jq -n '{"status": "done"}'

exit 0