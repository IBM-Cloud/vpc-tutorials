#!/bin/bash
# Purge resources created during a test

if [ ! "$TRAVIS" == "true" ];
then
  echo "Are you sure to delete all resources and VPCs under $RESOURCE_GROUP?"
  read confirmation
  if [[ "$confirmation" = "yes" || "$confirmation" = "YES" ]]; then
    echo "ok, going ahead..."
  else
    echo "exiting..."
    exit
  fi
fi

# ensure we target the test resource group
ibmcloud target -g $RESOURCE_GROUP


# find all resources in the target resource group and delete them
if RESOURCES=$(ibmcloud resource service-instances --output JSON)
then
  echo "${RESOURCES}" | jq -r '.[]| "\(.id) \(.guid) \(.sub_type)"' | while read resourceId resourceGuid resourceType
  do
    # crn:v1:bluemix:public:dns-svcs:global:a/713c783d9a507a53135fe6793c37cc74:2022678a-6806-4d89-bcf1-446287f6177d::
    serviceInstanceType=$(echo $resourceId | cut -d : -f 5)
    echo "Deleting ${resourceId} (${resourceGuid}, ${resourceType}, $serviceInstanceType)"

    # cleanup a KMS service from all its keys
    if [ $resourceType == "kms" ];
    then
      echo "Deleting keys in Key Protect service ${resourceGuid}"
      if KP_KEYS=$(ibmcloud kp keys -i "${resourceGuid}" --output json)
      then
        echo "$KP_KEYS" | jq -r  .[].id | while read keyId
        do
          echo "Removing key ${keyId}"
          ibmcloud kp key delete $keyId -i $resourceGuid -f
        done
      fi
    fi

    if [ "x$serviceInstanceType" == "xdns-svcs" ]; then
      customResolverJson=$(ibmcloud dns custom-resolvers --instance $resourceGuid --output json)
      for crId in $(jq -r '.[]|.id' <<< "$customResolverJson"); do
        ibmcloud dns custom-resolver-update  $crId --instance $resourceGuid --enabled false
        ibmcloud dns custom-resolver-delete $crId --instance $resourceGuid --force
      done
    fi

    # delete the actual service instance
    ibmcloud resource service-instance-delete "${resourceId}" -g $RESOURCE_GROUP -f --recursive
  done
else
  echo "Failed to get resources: ${RESOURCES}"
fi

# find all VPCs in the target resource group and delete them
RESOURCE_GROUP_ID=$(ibmcloud resource group $RESOURCE_GROUP --id)
if VPCS=$(ibmcloud is vpcs --output json)
then
  echo "$VPCS" | jq -r '.[] | select (.resource_group.id=="'$RESOURCE_GROUP_ID'") | .name' | while read vpcName
  do
    echo "Deleting VPC ${vpcName}"
    ./scripts/vpc-cleanup.sh ${vpcName} -f
  done
else
  echo "Failed to list VPCs: ${VPCS}"
fi

# delete any volumes left over
if VPC_VOLUMES=$(ibmcloud is volumes --resource-group-id $RESOURCE_GROUP_ID --output json)
then
  echo "$VPC_VOLUMES" | jq -r '.[] | select (.resource_group.id=="'$RESOURCE_GROUP_ID'") | .id' | while read volumeId
  do
    echo "Deleting volume ${volumeId}"
    ibmcloud is volume-delete ${volumeId} -f
  done
else
  echo "Failed to list keys: ${VPC_VOLUMES}"
fi

# delete any SSH keys left over
if VPC_KEYS=$(ibmcloud is keys --resource-group-id $RESOURCE_GROUP_ID --output json)
then
  echo "$VPC_KEYS" | jq -r '.[] | select(.name | startswith("automated-tests-")) | .id' | while read keyId
  do
    echo "Deleting key ${keyId}"
    ibmcloud is key-delete ${keyId} -f
  done
else
  echo "Failed to list keys: ${VPC_KEYS}"
fi
