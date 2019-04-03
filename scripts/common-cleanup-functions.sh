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
    echo "${VSI_IDs}" | jq -r '.[] | [.id,.floating_ips[]?.id] | @tsv' | while read nicid ipid 
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
    echo "${SGR_IDs}" | jq -r '.[].id' | while read ruleid
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
        export PG_IP_ID=$(ibmcloud is public-gateway $PGW_ID --json | jq -r '.floating_ip.id')
        echo "Detaching public gateway from subnet"
        ibmcloud is subnet-public-gateway-detach $SN_ID -f
        vpcGWDetached $SN_ID
        # because multiple subnets could use the same gateway, we will clean up later
    fi
    ibmcloud is vpn-gateways --json | jq -r '.[] | select (.subnet.id=="'${SN_ID}'") | [.id] | @tsv' | while read vpngwid
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
    LB_JSON=$(ibmcloud is load-balancers --json | jq -r '.[] | select(.name=="'$LB_NAME'")')
    LB_ID=$(echo "$LB_JSON" | jq -r '.id')
    POOL_IDS=$(echo "$LB_JSON" | jq -r '.pools[].id')

    echo "Deleting front-end listeners..."
    # First delete all, then check later for parallel deletion
    echo "$LB_JSON" | jq -r '.listeners[]?.id' | while read listenerid;
    do
        ibmcloud is load-balancer-listener-delete $LB_ID $listenerid -f
        sleep 20
    done
    echo "$LISTENER_IDS" | while read listenerid;
    do
        vpcLBDeleted load-balancer-listener-delete $LB_ID $listenerid
    done

    echo "Deleting back-end pool members and pools..."
    echo "$LB_JSON" | jq -r '.pools[]?.id' | while read poolid;
    do
        MEMBER_IDS=$(ibmcloud is load-balancer-pool-members $LB_ID $poolid --json | jq -r '.[]?.id')
        # Delete members first, then check for status later
        echo "$MEMBER_IDS" | while read memberid;
        do
            ibmcloud is load-balancer-pool-member-delete $LB_ID $poolid $memberid -f
            sleep 20
        done
        echo "$MEMBER_IDS" | while read memberid;
        do
            vpcLBDeleted load-balancer-pool-member-delete $LB_ID $poolid $memberid
        done
        # Delete pool
        ibmcloud is load-balancer-pool-delete $LB_ID $poolid -f
        sleep 20
        vpcLBDeleted load-balancer-pool-delete $LB_ID $poolid
    done
    echo "Deleting load balancer..."
    ibmcloud is load-balancer-delete $LB_ID -f
    #sleep 20
    vpcLBDeleted load-balancer-delete $LB_ID
}

# The following functions allow to pass in the name of a VPC and
# a pattern for matching the specific resource, e.g., a VSI.

# Delete VSIs
function deleteVSIsInVPCByPattern {
    local VPC_NAME=$1
    local VSI_TEST=$2
    VSI_IDs=$(ibmcloud is instances --json | jq -c '[.[] | select(.vpc.name=="'${VPC_NAME}'") | select(.name | test("'${VSI_TEST}'")) | {id: .id, name: .name}]')

    # Obtain all instances for VPC
    echo "$VSI_IDs" | jq -c -r '.[] | [.id] | @tsv' | while read vsiid
    do
        # delete but do not wait to have parallel processing of deletes
        deleteVSIbyID $vsiid false
    done

    # Loop over VSIs again once more to check the status
    echo "$VSI_IDs" | jq -c -r '.[] | [.id,.name] | @tsv ' | while read vsiid name
    do
        vpcResourceDeleted instance $vsiid
    done
}

# Delete Security Groups
function deleteSGsInVPCByPattern {
    local VPC_NAME=$1
    local SG_TEST=$2
    DEF_SG_ID=$(ibmcloud is vpcs --json | jq -r '.[] | select (.name=="'${vpcname}'") | .default_security_group.id')

    # Delete the non-default SGs
    VPC_SGs=$(ibmcloud is security-groups --json)
    # echo "Deleting Rules on Security Groups"
    echo "$VPC_SGs" | jq -r '.[] | select (.vpc.name=="'${vpcname}'" and .id!="'$DEF_SG_ID'") |select(.name | test("'${SG_TEST}'")) | [.id,.name] | @tsv' | while read sgid sgname
    do
        deleteRulesForSecurityGroupByID $sgid false
    done    
    # echo "Deleting Security Groups"
    echo "$VPC_SGs" | jq -r '.[] | select (.vpc.name=="'${vpcname}'" and .id!="'$DEF_SG_ID'") |select(.name | test("'${SG_TEST}'")) | [.id,.name] | @tsv' | while read sgid sgname
    do
        # echo "Deleting security group $sgname with id $sgid"
        deleteSecurityGroupByID $sgid true
    done    
}

# Delete subnets and related resources
function deleteSubnetsInVPCByPattern {
    local VPC_NAME=$1
    local SUBNET_TEST=$2
    ibmcloud is subnets --json | jq -r '.[] | select (.vpc.name=="'${vpcname}'") | select(.name | test("'${SUBNET_TEST}'"))  | [.id,.public_gateway?.id] | @tsv' | while read subnetid pgid
    do
        deleteSubnetbyID $subnetid $pgid
    done
}

# Delete Public Gateways
function deletePGWsInVPCByPattern {
    local VPC_NAME=$1
    local GW_TEST=$2
    ibmcloud is public-gateways --json | jq -r '.[] | select (.vpc.name=="'${vpcname}'") |select(.name | test("'${GW_TEST}'")) | [.id,.name] | @tsv' | while read pgid pgname
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
    ibmcloud is load-balancers --json | jq -r '.[] | select(.name | test("'${LB_TEST}'")) | [.name, .subnets[0].id] | @tsv' | while read lbname subnetid
    do
        lbvpcname=$(ibmcloud is subnet $subnetid --json | jq -r '.vpc.name')
        if [ "$lbvpcname" = "$VPC_NAME" ]; then
            deleteLoadBalancerByName $lbname
        fi
    done
}