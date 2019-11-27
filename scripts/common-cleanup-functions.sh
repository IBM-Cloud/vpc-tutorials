# Some common scripting functions for resource cleanup
#
# (C) 2019 IBM
#
# Written by Henrik Loeser, hloeser@de.ibm.com

# include common functions
. $(dirname "$0")/../scripts/common.sh


# Delete a virtual machine instance identified by its ID
# 1) Delete the network interfaces
# 2) Delete the machines (VSIs)
function deleteVSIbyID {
    VSI_ID=$1
    WAIT=$2
    # Look up VSI id
    VSI_IDs=$(ibmcloud is instance-network-interfaces $VSI_ID --json)
    echo "${VSI_IDs}" | jq -r '.[] | [.id,.floating_ips[]?.id] | @tsv' | tr -d '\r' | while read nicid ipid 
    do
        if [ $ipid ]; then
            echo "Removing floating IP with id $ipid for NIC with id $nicid"
            ibmcloud is instance-network-interface-floating-ip-remove $vsiid $nicid $ipid -f
            vpcResourceDeleted instance-network-interface-floating-ip $vsiid $nicid $ipid   
            # repeating the same in a different way, just in case
            echo "Releasing floating IP address"
            ibmcloud is floating-ip-release $ipid -f          
        fi
    done
    ibmcloud is instance-delete $vsiid -f
    # only wait for deletion to finish if asked so
    if [ "$WAIT" = "true" ]; then
        vpcResourceDeleted instance $vsiid
    fi
}


# Delete the rules for a specific Security Group
function deleteRulesForSecurityGroupByID {
    SG_ID=$1
    WAIT=$2
    # Delete the rules
    SGR_IDs=$(ibmcloud is security-group-rules $SG_ID --json)
    echo "${SGR_IDs}" | jq -r '.[].id' | tr -d '\r' | while read ruleid
    do
        ibmcloud is security-group-rule-delete $SG_ID $ruleid -f
        # only wait for deletion to finish if asked so
        if [ "$WAIT" = "true" ]; then
            vpcResourceDeleted security-group-rule $SG_ID $ruleid
        fi
    done
}


# Delete a security group and its rules. The SG is identified
# by its ID.
function deleteSecurityGroupByID {
    SG_ID=$1
    WAIT=$2
    # Delete the rules, there after the group itself
    deleteRulesForSecurityGroupByID $SG_ID true
    ibmcloud is security-group-delete $SG_ID -f
    # only wait for deletion to finish if asked so
    if [ "$WAIT" = "true" ]; then
        vpcResourceDeleted security-group $SG_ID
    fi
}


# Delete a subnet and its resources:
# - Attached Public Gateway
# - VPN Gateway
# Waits for deletion to be finished.
function deleteSubnetbyID {
    SN_ID=$1
    PGW_ID=$2
    if [ $PGW_ID ]; then
        echo "Detaching public gateway from subnet"
        ibmcloud is subnet-public-gateway-detach $SN_ID
        vpcGWDetached $SN_ID
        # because multiple subnets could use the same gateway, we will clean up later
    fi
      VPN_GWs=$(ibmcloud is vpn-gateways --json)
      echo "${VPN_GWs}" | jq -r '.[] | select (.subnet.id=="'${SN_ID}'") | [.id] | @tsv' | tr -d '\r' | while read vpngwid
      do
          ibmcloud is vpn-gateway-delete $vpngwid -f
          vpcResourceDeleted vpn-gateway $vpngwid
      done
    ibmcloud is subnet-delete $SN_ID -f
    vpcResourceDeleted subnet $SN_ID
}

# Delete a load balancer, its pool and listeners
function deleteLoadBalancerByName {
    LB_NAME=$1
    LBs=$(ibmcloud is load-balancers --json)
    LB_JSON=$(echo "${LBs}" | jq -r '.[] | select(.name=="'$LB_NAME'")')
    LB_ID=$(echo "$LB_JSON" | jq -r '.id')
    POOL_IDS=$(echo "$LB_JSON" | jq -r '.pools[].id')

    echo "Deleting IAM service authorizations for load balancer, likely to the certificate manager, for load balancer $LB_NAME"
    EXISTING_POLICIES=$(ibmcloud iam authorization-policies --output JSON)
    authorization_policy_for_lb=$(echo "$EXISTING_POLICIES" | jq -r '.[] | select(
      .subjects[].attributes[]=={"name": "resourceType", "value": "load-balancer"}
      and .subjects[].attributes[]=={"name": "serviceInstance", "value": "'$LB_ID'"}
    ) | .id')
    for authorization_policy in ${authorization_policy_for_lb}; do
      ibmcloud iam authorization-policy-delete $authorization_policy -f
    done

    echo "Deleting front-end listeners..."
    # First delete all, then check later for parallel deletion
    echo "$LB_JSON" | jq -r '.listeners[]?.id' | while read listenerid;
    do
        ibmcloud is load-balancer-listener-delete $LB_ID $listenerid -f
        loadBalancerChangeComplete $LB_ID; # can not perform any other operation until previous operation is complete
    done
    echo "$LB_JSON" | jq -r '.listeners[]?.id' | while read listenerid;
    do
        vpcResourceDeleted load-balancer-listener $LB_ID $listenerid
    done

    echo "Deleting back-end pool members and pools..."
    echo "$LB_JSON" | jq -r '.pools[]?.id' | while read poolid;
    do
        POOL_MEMBERS=$(ibmcloud is load-balancer-pool-members $LB_ID $poolid --json)
        MEMBER_IDS=$(echo "${POOL_MEMBERS}" | jq -r '.[]?.id')
        # Delete members first, then check for status later
        if [ "x$MEMBER_IDS" != x ]; then
            echo "$MEMBER_IDS" | while read memberid;
            do
                ibmcloud is load-balancer-pool-member-delete $LB_ID $poolid $memberid -f
                loadBalancerChangeComplete $LB_ID; # can not perform any other operation until previous operation is complete
            done
            echo "$MEMBER_IDS" | while read memberid;
            do
                vpcResourceDeleted load-balancer-pool-member $LB_ID $poolid $memberid
            done
        fi
        # Delete pool
        ibmcloud is load-balancer-pool-delete $LB_ID $poolid -f
        loadBalancerChangeComplete $LB_ID; # can not perform any other operation until previous operation is complete
        vpcResourceDeleted load-balancer-pool $LB_ID $poolid
    done
    echo "Deleting load balancer..."
    ibmcloud is load-balancer-delete $LB_ID -f
    vpcResourceDeleted load-balancer $LB_ID
}

# The following functions allow to pass in the name of a VPC and
# a pattern for matching the specific resource, e.g., a VSI.

# Delete VSIs
function deleteVSIsInVPCByPattern {
    local VPC_NAME=$1
    local VSI_TEST=$2
    VSIs=$(ibmcloud is instances --json)
    VSI_IDs=$(echo "${VSIs}" | jq -c '[.[] | select(.vpc.name=="'${VPC_NAME}'") | select(.name | test("'${VSI_TEST}'")) | {id: .id, name: .name}]')
     
    if is_generation_2; then
        # stop all the instances
        echo "$VSI_IDs" | jq -c -r '.[] | [.id] | @tsv' | tr -d '\r' | while read vsiid
        do
            ibmcloud is instance-stop $vsiid -f
        done

        # Loop over VSIs again once more to check the status
        echo "$VSI_IDs" | jq -c -r '.[] | [.id,.name] | @tsv' | tr -d '\r' | while read vsiid name
        do
            instanceIdStopped $vsiid
        done
    fi
    # delete all the instances
    echo "$VSI_IDs" | jq -c -r '.[] | [.id] | @tsv' | tr -d '\r' | while read vsiid
    do
        # delete but do not wait to have parallel processing of deletes
        deleteVSIbyID $vsiid false
    done

    # Loop over VSIs again once more to check the status
    echo "$VSI_IDs" | jq -c -r '.[] | [.id,.name] | @tsv' | tr -d '\r' | while read vsiid name
    do
        vpcResourceDeleted instance $vsiid
    done
}

# Delete Security Groups
function deleteSGsInVPCByPattern {
    local VPC_NAME=$1
    local SG_TEST=$2
    VPCs=$(ibmcloud is vpcs --json)
    DEF_SG_ID=$(echo "${VPCs}" | jq -r '.[] | select (.name=="'${VPC_NAME}'") | .default_security_group.id')

    # Delete the non-default SGs
    VPC_SGs=$(ibmcloud is security-groups --json)
    # echo "Deleting Rules on Security Groups"
    echo "$VPC_SGs" | jq -r '.[] | select (.vpc.name=="'${VPC_NAME}'" and .id!="'$DEF_SG_ID'") |select(.name | test("'${SG_TEST}'")) | [.id,.name] | @tsv' | tr -d '\r' | while read sgid sgname
    do
        deleteRulesForSecurityGroupByID $sgid false
    done    
    # echo "Deleting Security Groups"
    echo "$VPC_SGs" | jq -r '.[] | select (.vpc.name=="'${VPC_NAME}'" and .id!="'$DEF_SG_ID'") |select(.name | test("'${SG_TEST}'")) | [.id,.name] | @tsv' | tr -d '\r' | while read sgid sgname
    do
        # echo "Deleting security group $sgname with id $sgid"
        deleteSecurityGroupByID $sgid true
    done    
}

# Delete subnets and related resources
function deleteSubnetsInVPCByPattern {
    local VPC_NAME=$1
    local SUBNET_TEST=$2
    SUBNETs=$(ibmcloud is subnets --json)
    echo "${SUBNETs}" | jq -r '.[] | select (.vpc.name=="'${VPC_NAME}'") | select(.name | test("'${SUBNET_TEST}'"))  | [.id,.public_gateway?.id] | @tsv' | tr -d '\r' | while read subnetid pgid
    do
        deleteSubnetbyID $subnetid $pgid
    done
}

# Delete Public Gateways
function deletePGWsInVPCByPattern {
    local VPC_NAME=$1
    local GW_TEST=$2
    PUB_GWs=$(ibmcloud is public-gateways --json)
    echo "${PUB_GWs}" | jq -r '.[] | select (.vpc.name=="'${VPC_NAME}'") |select(.name | test("'${GW_TEST}'")) | [.id,.name] | @tsv' | tr -d '\r' | while read pgid pgname
    do
        # echo "Deleting public gateway with id $pgid and name $pgname"
        ibmcloud is public-gateway-delete $pgid -f
        vpcResourceDeleted public-gateway $pgid
    done
}

# Delete Load Balancer and related resources
function deleteLoadBalancersInVPCByPattern {
    local VPC_NAME=$1
    local LB_TEST=$2
    LBs=$(ibmcloud is load-balancers --json)
    echo "${LBs}" | jq -r '.[] | select(.name | test("'${LB_TEST}'")) | [.name, .subnets[0].id] | @tsv' | tr -d '\r' | while read lbname subnetid
    do
        CMD_OUTPUT=$(ibmcloud is subnet $subnetid --json)
        if [ $? -eq 0 ]; then
            lbvpcname=$(echo $CMD_OUTPUT | jq -r '.vpc.name')
            if [ "$lbvpcname" = "$VPC_NAME" ]; then
                deleteLoadBalancerByName $lbname
            fi
        else
            >&2 echo "cmd failed: $CMD_OUTPUT"
        fi
    done
}
