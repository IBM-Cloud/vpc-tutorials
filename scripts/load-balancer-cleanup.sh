#!/bin/bash

if [ -z "$1" ]; then
    echo "usage: $0 load-balancer-name"
    echo "Removes load balancer and its related resources"
    exit
fi
export lbname=$1

#ibmcloud is subnet $(ibmcloud is lbs --json | jq -r '.[] | select (.name=="'$lbname'")| .subnets | .[1] | .id'  ) --json | jq -r '.vpc.name'

LB_ID=$(ibmcloud is lbs --json | jq -r '.[] | select(.name="'$lbname'").id')
LB_JSON=$(ibmcloud is lb $LB_ID --json)
LISTENER_IDS=$(echo "$LB_JSON" | jq -r '.listeners[].id')
POOL_IDS=$(echo "$LB_JSON" | jq -r '.pools[].id')

echo "Deleting front-end listeners..."
echo "$LISTENER_IDS" | while read listenerid;
do
    ibmcloud is load-balancer-listener-delete $LB_ID $listenerid -f
    sleep 20
done

sleep 20

echo "Deleting back-end pool members and pools..."
echo "$POOL_IDS" | while read poolid;
do
    MEMBER_IDS=$(ibmcloud is load-balancer-pool-members $LB_ID $poolid --json | jq -r '.[].id')
    echo "$MEMBER_IDS" | while read memberid;
    do
        ibmcloud is load-balancer-pool-member-delete $LB_ID $poolid $memberid -f
        sleep 20
    done
    ibmcloud is load-balancer-pool-delete $LB_ID $poolid -f
done

sleep 20

echo "Deleting load balancer..."
ibmcloud is load-balancer-delete $LB_ID -f