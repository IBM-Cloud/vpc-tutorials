#!/bin/bash
# Purge resources created during a test
this_dir=$(dirname "$0")
source $this_dir/tests_common.sh
source $this_dir/../scripts/common.sh

# ensure we target the test resource group
ibmcloud target -g $RESOURCE_GROUP

# Delete the temporary SSH key
TEST_KEY_NAME=$(ssh_key_name_for_job)
ssh_key_delete_if_exists $TEST_KEY_NAME

# find all resources in the target resource group and delete them
if RESOURCES=$(ibmcloud resource service-instances --output JSON)
then
  echo "${RESOURCES}" | jq -r '.[]| "\(.id) \(.guid) \(.sub_type)"' | while read resourceId resourceGuid resourceType
  do
    echo "Deleting ${resourceId} (${resourceGuid}, ${resourceType})"

    # cleanup a KMS service from all its keys
    if [ $resourceType == "kms" ];
    then
      echo "Deleting keys in Key Protect service ${resourceGuid}"
      if KP_KEYS=$(ibmcloud kp list -i "${resourceGuid}" --output json)
      then
        echo "$KP_KEYS" | jq -r  .[].id | while read keyId
        do
          echo "Removing key ${keyId}"
          ibmcloud kp delete $keyId -i $resourceGuid
        done
      fi
    fi

    # delete the actual service instance
    ibmcloud resource service-instance-delete "${resourceId}" -g $RESOURCE_GROUP -f --recursive
  done
else
  echo "Failed to get resources: ${RESOURCES}"
fi

# find all VPCs in the target resource group and delete them
RESOURCE_GROUP_ID=$(ibmcloud resource group $RESOURCE_GROUP --id)
if VPCS=$(ibmcloud is vpcs --json)
then
  echo "$VPCS" | jq -r '.[] | select (.resource_group.id=="'$RESOURCE_GROUP_ID'") | .name' | while read vpcName
  do
    echo "Deleting VPC ${vpcName}"
    ./scripts/vpc-cleanup.sh ${vpcName} -f
  done
else
  echo "Failed to list VPCs: ${VPCS}"
fi
