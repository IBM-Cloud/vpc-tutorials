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
    ibmcloud is instance-network-interfaces $VSI_ID --json | jq -r '.[] | [.id,.floating_ips[]?.id] | @tsv' | while read nicid ipid 
    do
        if [ $ipid ]; then
            echo "Deleting floating IP with id $ipid for NIC with id $nicid"
            ibmcloud is instance-network-interface-floating-ip-remove $vsiid $nicid $ipid -f
            # repeating the same in a different way, just in case
            ibmcloud is floating-ip-release $ipid -f > /dev/null
            vpcResourceDeleted instance-network-interface-floating-ip $vsiid $nicid $ipid            
        fi
    done
    ibmcloud is instance-delete $vsiid -f
    # only wait for deletion to finish if asked so
    if [ "$WAIT" = "true" ]; then
        vpcResourceDeleted instance $vsiid
    fi
}

# Delete a security group and its rules. The SG is identified
# by its ID.
function deleteSecurityGroupByID {
    SG_ID=$1
    WAIT=$2
    # Delete the rules, there after the group itself
    ibmcloud is security-group-rules $SG_ID --json | jq -r '.[].id' | while read ruleid
    do
        ibmcloud is security-group-rule-delete $SG_ID $ruleid -f
        vpcResourceDeleted security-group-rule $SG_ID $ruleid
    done
    ibmcloud is security-group-delete $SG_ID -f
    # only wait for deletion to finish if asked so
    if [ "$WAIT" = "true" ]; then
        vpcResourceDeleted security-group $SG_ID
    fi
}

function deleteRulesForSecurityGroupByID {
    SG_ID=$1
    WAIT=$2
    # Delete the rules
    ibmcloud is security-group-rules $SG_ID --json | jq -r '.[].id' | while read ruleid
    do
        ibmcloud is security-group-rule-delete $SG_ID $ruleid -f
        # only wait for deletion to finish if asked so
        if [ "$WAIT" = "true" ]; then
            vpcResourceDeleted security-group-rule $SG_ID $ruleid
        fi
    done
}

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
