#!/bin/bash
#set -ex

# Script to deploy ssh keys for IBM Cloud VPC Virtual Server Instances based on Compute Identity.
#
# (C) 2021 IBM
#
# Written by Dimitri Prosper, dimitri_prosper@us.ibm.com
#
#
#

# Exit on errors
set -o errexit
set -o pipefail
# set -o nounset

log_file=/var/log/ssh-authorized-keys.log
exec 3>&1 1>>$${log_file} 2>&1

function log_info {
  printf "$(date '+%Y-%m-%d %T') %s\n" "$@"
  printf "\e[1;34m$(date '+%Y-%m-%d %T') %s\e[0m\n" "$@" 1>&3
}

function log_success {
  printf "$(date '+%Y-%m-%d %T') %s\n" "$@"
  printf "\e[1;32m$(date '+%Y-%m-%d %T') %s\e[0m\n" "$@" 1>&3
}

function log_warning {
  printf "$(date '+%Y-%m-%d %T') %s\n" "$@"
  printf "\e[1;33m$(date '+%Y-%m-%d %T') %s\e[0m\n" "$@" 1>&3
}

function log_error {
  printf $(date '+%Y-%m-%d %T')" $@"
  printf >&2 "\e[1;31m$(date '+%Y-%m-%d %T') %s\e[0m\n" "$@" 1>&3
}

log_info "Verifying jq is installed/in the path."
type jq >/dev/null 2>&1 || { log_error "This script requires jq, but it's not installed."; exit 1; }

while [ true ]
do
  log_info "Getting instance identity access token."
  access_token=`curl -s -X PUT "http://169.254.169.254/instance_identity/v1/token?version=2021-10-12"\
    -H "Metadata-Flavor: ibm"\
    -H "Accept: application/json"\
    -d '{
          "expires_in": 3600
        }' | jq -r '(.access_token)'`

  log_info "Getting instance metadata."
  curl -s -X GET "http://169.254.169.254/metadata/v1/instance?version=2021-09-10"\
    -H "Accept:application/json"\
    -H "Authorization: Bearer $${access_token}" > /tmp/instance.json

  zone=$(jq -r '.zone.name' /tmp/instance.json)
  region=$(echo $${zone} | awk '{ print substr( $0, 1, length($0)-2 ) }')
  instance_name=$(jq -r '.name' /tmp/instance.json)
  instance_id=$(jq -r '.id' /tmp/instance.json)

  if [ ! -z $${region} ]; then
    log_info "Getting IAM token using profile_id ${profileid}."
    curl -s -X POST\
        -H "Content-Type: application/x-www-form-urlencoded"\
        -H "Accept: application/json"\
        -d grant_type=urn:ibm:params:oauth:grant-type:cr-token\
        -d cr_token=$${access_token}\
        -d profile_id=${profileid}\
        https://iam.cloud.ibm.com/identity/token > /tmp/get_iam_token.json

    error_code=$(jq -r '.errorCode' /tmp/get_iam_token.json)
    if [ -z $${error_code} ] || [ $${error_code} = "null" ]; then

      iam_token=$(jq -r '.access_token' /tmp/get_iam_token.json)
      if [ ! -z $${iam_token} ]; then

        log_info "Getting list of SSH Keys authorized for $${instance_name} with id $${instance_id} in region $${region}."

        curl -s -X GET "https://$${region}.iaas.cloud.ibm.com/v1/keys?version=2021-09-07&generation=2" -H "Authorization: $${iam_token}" | jq '.keys' > keys.json 
        
        keys_count=$(jq length keys.json)
        if [ $${keys_count} -eq 0 ]; then
          log_warning "No SSH keys found for $${instance_name} with id $${instance_id} in region $${region}, last saved authorized_keys is maintained."
        else
          log_info "Found $${keys_count} SSH keys for $${instance_name} with id $${instance_id} in region $${region}."

          keys=$(jq -c '.[] | {id, name}' keys.json)
          for key in $${keys}; do
            key_id=$(echo $${key} | jq -r '.id | select (.!=null)')
            key_name=$(echo $${key} | jq -r '.name | select (.!=null)')
            log_info "Writting SSH Key $${key_name} with id $${key_id} to authorized_keys."
          done

          jq -r '.[] | .public_key' keys.json  > ~/.ssh/authorized_keys
        fi
      fi
    else 
      log_warning "Encountered error getting IAM token $${error_code}."
      log_error "Encountered error getting IAM token $${error_code}."
    fi
  fi
  sleep ${cyclewaitseconds}
done
exit 0