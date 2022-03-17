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

function deleteCerts {
   log_info "Started deleteCerts."

   ibmcloud login --apikey ${ibmcloud_api_key} -r ${region} -g ${resource_group_id} 2>&1 >/dev/null
   [ $? -ne 0 ] && return 1

   iam_oauth_tokens=$(ibmcloud iam oauth-tokens --output json)
   [ $? -ne 0 ] && return 1

   iam_token=$(echo "$${iam_oauth_tokens}" | jq -r '.iam_token')

   sm_host=${sm_instance_id}.${region}.secrets-manager.appdomain.cloud

   sm_group_id=$(ibmcloud secrets-manager secret-groups --service-url https://$${sm_host} --output json | jq -r --arg sm_group ${sm_group} '.resources[] | select(.name == $sm_group) | .id')
   [ $? -ne 0 ] && return 1

   secrets=$(ibmcloud secrets-manager all-secrets --groups $${sm_group_id} --service-url https://$${sm_host} --output json | jq .resources[].id -r | tr -d '\r')
   [ $? -ne 0 ] && return 1

   for secret in $${secrets}; do 
      ibmcloud secrets-manager secret-delete \
      --secret-type imported_cert \
      --id $${secret} \
      --force \
      --service-url https://$${sm_host}
   done

   secret_group_json=$(ibmcloud secrets-manager secret-group-delete \
   --id $${sm_group_id} \
   --force \
   --service-url https://$${sm_host} \
   )
   [ $? -ne 0 ] && return 1

   ibmcloud logout
}

function first_boot_setup {
    log_info "Started $name server configuration"
    
    deleteCerts
    [ $? -ne 0 ] && log_error "Failed deleteCerts, review log file $log_file." && return 1

    return 0
}

first_boot_setup
[ $? -ne 0 ] && log_error "admin server destroy had errors." && exit 1

exit 0