#!/bin/bash

name=cockroachdb-admin-systemd
log_file=$name.$(date +%Y%m%d_%H%M%S).log
exec 3>&1 1>>$log_file 2>&1

function log_info {
    printf "\e[1;34m$(date '+%Y-%m-%d %T') %s\e[0m\n" "$@" 1>&3
}

function log_success {
    printf "\e[1;32m$(date '+%Y-%m-%d %T') %s\e[0m\n" "$@" 1>&3
}

function log_warning {
    printf "\e[1;33m$(date '+%Y-%m-%d %T') %s\e[0m\n" "$@" 1>&3
}

function log_error {
    printf >&2 "\e[1;31m$(date '+%Y-%m-%d %T') %s\e[0m\n" "$@" 1>&3
}

function installNTP {

    log_info "Running apt-get update."
    apt-get update
    [ $? -ne 0 ] && log_error "apt-get update command execution error." && return 1

    log_info "Running apt-get install ntp and jq."
    apt-get install ntp jq -y
    [ $? -ne 0 ] && log_error "apt-get install command execution error." && return 1

    log_info "Stopping ntp service."
    service ntp stop

    log_info "Modifying /etc/ntp.conf."

    cp /etc/ntp.conf /etc/ntp.conf.orig

    sed -i '/pool /s/^/#/g' /etc/ntp.conf
    sed -i '/server /s/^/#/g' /etc/ntp.conf

cat >> /etc/ntp.conf <<- EOF
server time.adn.networklayer.com iburst
EOF

    log_info "Starting ntp service."
    service ntp start

    return 0
}

function installCockroachDB {
  log_info "Started installCockroachDB."

    if [ ! -f "/usr/local/bin/${app_binary}" ]; then

        log_info "wget --output-document=${app_binary_archive} ${app_url}/${app_binary_archive}."
        wget --output-document=${app_binary_archive} ${app_url}/${app_binary_archive}
        [ $? -ne 0 ] && log_error "File not found" && exit 1

        tar xvf ${app_binary_archive}
        cp ${app_directory}/${app_binary} /usr/local/bin
        rm -rf ${app_directory}

        log_info "mkdir /var/lib/cockroach."
        mkdir /var/lib/cockroach

        log_info "useradd ${app_user}."
        useradd ${app_user}

        log_info "chown ${app_user} /var/lib/cockroach."
        chown ${app_user} /var/lib/cockroach
    fi
    return 0
}

function createCerts {
  log_info "Started createCerts."

  if [ ! -f "${ca_directory}/ca.key" ]; then

    mkdir /${certs_directory}

    mkdir /${ca_directory}

    cockroach cert create-ca --certs-dir=/${certs_directory} --ca-key=/${ca_directory}/ca.key
    sleep 5

    cockroach cert create-node ${db_node1_address} localhost 127.0.0.1 ${lb_hostname} --certs-dir=/${certs_directory} --ca-key=/${ca_directory}/ca.key
    sleep 5
    mv /${certs_directory}/node.crt /${certs_directory}/${db_node1_address}.node.crt
    mv /${certs_directory}/node.key /${certs_directory}/${db_node1_address}.node.key

    cockroach cert create-node ${db_node2_address} localhost 127.0.0.1 ${lb_hostname} --certs-dir=/${certs_directory} --ca-key=/${ca_directory}/ca.key
    sleep 5
    mv /${certs_directory}/node.crt /${certs_directory}/${db_node2_address}.node.crt
    mv /${certs_directory}/node.key /${certs_directory}/${db_node2_address}.node.key

    cockroach cert create-node ${db_node3_address} localhost 127.0.0.1 ${lb_hostname} --certs-dir=/${certs_directory} --ca-key=/${ca_directory}/ca.key
    sleep 5
    mv /${certs_directory}/node.crt /${certs_directory}/${db_node3_address}.node.crt
    mv /${certs_directory}/node.key /${certs_directory}/${db_node3_address}.node.key

    cockroach cert create-client root --certs-dir=/${certs_directory} --ca-key=/${ca_directory}/ca.key
    cockroach cert create-client maxroach --certs-dir=/${certs_directory} --ca-key=/${ca_directory}/ca.key

  fi
  return 0

}

function importCerts {
   log_info "Started importCerts."

   curl -sL https://ibm.biz/idt-installer | bash
   [ $? -ne 0 ] && return 1

   ibmcloud plugin install secrets-manager -f
   [ $? -ne 0 ] && return 1

   ibmcloud login --apikey ${ibmcloud_api_key} -r ${region} -g ${resource_group_id} 2>&1 >/dev/null
   [ $? -ne 0 ] && return 1

   iam_oauth_tokens=$(ibmcloud iam oauth-tokens --output json)
   [ $? -ne 0 ] && return 1

   iam_token=$(echo "$${iam_oauth_tokens}" | jq -r '.iam_token')

   sm_host=${sm_instance_id}.${region}.secrets-manager.appdomain.cloud

   secret_group_json=$(ibmcloud secrets-manager secret-group-create \
   --resources='[
      {
         "name": "${sm_group}",
         "description": "Used to hold secrets for the cockroachdb scenario."
      }
   ]' \
   --output json \
   --service-url https://$${sm_host} \
   )
   [ $? -ne 0 ] && return 1

   secret_group_id=$(echo $${secret_group_json} | jq -r .resources[0].id)

   certificate=$(cat "/${certs_directory}/${db_node1_address}.node.crt" | jq -Rsr 'tojson')
   privateKey=$(cat "/${certs_directory}/${db_node1_address}.node.key" | jq -Rsr 'tojson')
   intermediate=$(cat "/${certs_directory}/ca.crt" | jq -Rsr 'tojson')
cat > "/${certs_directory}/${db_node1_address}.cert.json" <<- EOF
{
  "metadata": {
    "collection_type": "application/vnd.ibm.secrets-manager.secret+json",
    "collection_total": 1
  },
  "resources": [
    {
      "name": "${db_node1_address}",
      "description": "cockroach cert",
      "secret_group_id": "$${secret_group_id}",
      "labels": [
        "cockroach"
      ],
      "certificate": $${certificate},
      "private_key": $${privateKey},
      "intermediate": $${intermediate}
    }
  ]
}
EOF
   curl -s -X POST -H "Content-Type: application/json" -H "authorization: $${iam_token}" -d @${certs_directory}/${db_node1_address}.cert.json "https://$${sm_host}/api/v1/secrets/imported_cert" 2>&1 >/dev/null

   certificate=$(cat "/${certs_directory}/${db_node2_address}.node.crt" | jq -Rsr 'tojson')
   privateKey=$(cat "/${certs_directory}/${db_node2_address}.node.key" | jq -Rsr 'tojson')
   intermediate=$(cat "/${certs_directory}/ca.crt" | jq -Rsr 'tojson')
cat > "/${certs_directory}/${db_node2_address}.cert.json" <<- EOF
{
  "metadata": {
    "collection_type": "application/vnd.ibm.secrets-manager.secret+json",
    "collection_total": 1
  },
  "resources": [
    {
      "name": "${db_node2_address}",
      "description": "cockroach cert",
      "secret_group_id": "$${secret_group_id}",
      "labels": [
        "cockroach"
      ],
      "certificate": $${certificate},
      "private_key": $${privateKey},
      "intermediate": $${intermediate}
    }
  ]
}
EOF
   curl -s -X POST -H "Content-Type: application/json" -H "authorization: $${iam_token}" -d @${certs_directory}/${db_node2_address}.cert.json "https://$${sm_host}/api/v1/secrets/imported_cert" 2>&1 >/dev/null

   certificate=$(cat "/${certs_directory}/${db_node3_address}.node.crt" | jq -Rsr 'tojson')
   privateKey=$(cat "/${certs_directory}/${db_node3_address}.node.key" | jq -Rsr 'tojson')
   intermediate=$(cat "/${certs_directory}/ca.crt" | jq -Rsr 'tojson')
cat > "/${certs_directory}/${db_node3_address}.cert.json" <<- EOF
{
  "metadata": {
    "collection_type": "application/vnd.ibm.secrets-manager.secret+json",
    "collection_total": 1
  },
  "resources": [
    {
      "name": "${db_node3_address}",
      "description": "cockroach cert",
      "secret_group_id": "$${secret_group_id}",
      "labels": [
        "cockroach"
      ],
      "certificate": $${certificate},
      "private_key": $${privateKey},
      "intermediate": $${intermediate}
    }
  ]
}
EOF
   curl -s -X POST -H "Content-Type: application/json" -H "authorization: $${iam_token}" -d @${certs_directory}/${db_node3_address}.cert.json "https://$${sm_host}/api/v1/secrets/imported_cert" 2>&1 >/dev/null

   certificate=$(cat "/${certs_directory}/client.maxroach.crt" | jq -Rsr 'tojson')
   privateKey=$(cat "/${certs_directory}/client.maxroach.key" | jq -Rsr 'tojson')
   intermediate=$(cat "/${certs_directory}/ca.crt" | jq -Rsr 'tojson')
cat > "/${certs_directory}/maxroach.cert.json" <<- EOF
{
  "metadata": {
    "collection_type": "application/vnd.ibm.secrets-manager.secret+json",
    "collection_total": 1
  },
  "resources": [
    {
      "name": "maxroach",
      "description": "cockroach cert",
      "secret_group_id": "$${secret_group_id}",
      "labels": [
        "cockroach"
      ],
      "certificate": $${certificate},
      "private_key": $${privateKey},
      "intermediate": $${intermediate}
    }
  ]
}
EOF
   curl -s -X POST -H "Content-Type: application/json" -H "authorization: $${iam_token}" -d @${certs_directory}/maxroach.cert.json "https://$${sm_host}/api/v1/secrets/imported_cert" 2>&1 >/dev/null

   ibmcloud logout
}

function first_boot_setup {
    log_info "Started $name server configuration from cloud-init."

    log_info "Checking apt lock status"
    is_apt_running=$(ps aux | grep -i apt | grep lock_is_held | wc -l)
    until [ "$is_apt_running" = 0 ]; do
        log_warning "Sleeping for 30 seconds while apt lock_is_held."
        sleep 30
        
        log_info "Checking apt lock status"
        is_apt_running=$(ps aux | grep -i apt | grep lock_is_held | wc -l)
    done

    installNTP
    [ $? -ne 0 ] && log_error "Failed NTP installation, review log file $log_file." && return 1
    
    installCockroachDB
    [ $? -ne 0 ] && log_error "Failed installCockroachDB, review log file $log_file." && return 1

    sleep 10
    createCerts
    [ $? -ne 0 ] && log_error "Failed createCerts, review log file $log_file." && return 1
    
    importCerts
    [ $? -ne 0 ] && log_error "Failed importCerts, review log file $log_file." && return 1

    return 0
}

first_boot_setup
[ $? -ne 0 ] && log_error "admin server setup had errors." && exit 1

exit 0