#!/bin/bash

set -e

eval "$(jq -r '@sh "ibmcloud_api_key=\(.ibmcloud_api_key) region=\(.region) resource_group_id=\(.resource_group_id) key_name=\(.key_name) service_instance_id=\(.service_instance_id) config_directory=\(.config_directory)" ')"

ibmcloud login --apikey ${ibmcloud_api_key} -r ${region} -g ${resource_group_id} 2>&1 >/dev/null
[ $? -ne 0 ] && exit 1

# warm-up time?
sleep 30

echo "ibmcloud kp list -c --instance-id ${service_instance_id} --output json | jq -r 'select (.!=null)'" 1>&2
key_protect_list_response=$(ibmcloud kp list -c --instance-id ${service_instance_id} --output json | jq -r 'select (.!=null)')
[ $? -ne 0 ] && exit 1

if [ ! -z "${key_protect_list_response}" ]; then
  key_crn=$(echo ${key_protect_list_response} | jq -r --arg key_name ${key_name} 'select (.!=null) | .[] | select(.name == $key_name) | .crn' | tr -d '\n\r')
  key_id=$(echo ${key_protect_list_response} | jq -r --arg key_name ${key_name} 'select (.!=null) | .[] | select(.name == $key_name) | .id' | tr -d '\n\r')
fi

if [ -z "${key_crn}" ]; then
    key_protect_create_response=$(ibmcloud kp create ${key_name} --instance-id ${service_instance_id} --output json)
    [ $? -ne 0 ] && exit 1

    key_protect_list_response=$(ibmcloud kp list -c --instance-id ${service_instance_id} --output json | jq -r 'select (.!=null)')
    [ $? -ne 0 ] && exit 1

    if [ -z "${key_protect_list_response}" ]; then
      # A key protect crn was not found unable to create data_volume without a key_protect key."
      exit 1
    fi

    key_crn=$(echo ${key_protect_list_response} | jq -r --arg key_name ${key_name} 'select (.!=null) | .[] | select(.name == $key_name) | .crn' | tr -d '\n\r')
    key_id=$(echo ${key_protect_list_response} | jq -r --arg key_name ${key_name} 'select (.!=null) | .[] | select(.name == $key_name) | .id' | tr -d '\n\r')
fi

authorization_policies=$(ibmcloud iam authorization-policies --output json)
[ $? -ne 0 ] && exit 1

iam_authorization_response=$(echo "${authorization_policies}" | jq -r --arg source_service_name server-protect --arg source_service_role Reader --arg service_name kms --arg service_instance_id ${service_instance_id} '.[] | select(.subjects[].attributes[].value == $source_service_name) | select(.roles[].display_name == $source_service_role) | select(.resources[].attributes[].value == $service_name) | select(.resources[].attributes[].value == $service_instance_id)')

if [ -z "${iam_authorization_response}" ]; then
  iam_authorization_response=$(ibmcloud iam authorization-policy-create server-protect kms Reader --target-service-instance-id ${service_instance_id} --output json)
  [ $? -ne 0 ] && exit 1
fi

authorization_id=$(echo "${iam_authorization_response}" | jq -r '.id')

delete=$(echo "ibmcloud kp delete ${key_id} --instance-id ${service_instance_id} && sleep 30" > ${config_directory}/key-protect-delete.sh)

jq -n --arg key_crn "${key_crn}" --arg key_id "${key_id}" --arg authorization_id "${authorization_id}" '{"key_crn":$key_crn, "key_id":$key_id, "authorization_id":$authorization_id}'

# warm-up time?
sleep 30

exit 0