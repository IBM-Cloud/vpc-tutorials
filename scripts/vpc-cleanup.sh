#!/bin/bash

# Script to clean up VPC resources
#
# (C) 2019 IBM
#
# Written by Henrik Loeser, hloeser@de.ibm.com

# include common functions
. $(dirname "$0")/../scripts/common.sh


if [ -z "$1" ]; then 
    echo "usage: $0 vpc-name"
    echo "Removes a VPC and its related resources"         
    exit
fi
export vpcname=$1

if [ -z "$2" ]; then 
  echo "Are you sure to delete VPC $vpcname and its related resources? [yes/NO]"
  read confirmation
else
  confirmation=$2
fi

if [[ "$confirmation" = "yes" || "$confirmation" = "YES" ]]; then
    echo "ok, going ahead..."
else
    echo "exiting..."
    exit
fi


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



# Start the actual cleanup processing for a given VPC name
# 1) Loop over VSIs
# 2) Delete the security groups
# 3) Remove the subnets and their related resources
# 4) Delete the VPC itself


# Obtain all instances for VPC
export VSI_IDs=$(ibmcloud is instances --json |\
       jq -c '[.[] | select (.vpc.name=="'${vpcname}'") | {id: .id, name: .name}]')


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




# To delete the security groups we have to consider
# 1) Do not touch the default SG
# 2) First, delete all rules because of cross references
# 3) Then, delete the SGs

export DEF_SG_ID=$(ibmcloud is vpcs --json | jq -r '.[] | select (.name=="'${vpcname}'") | .default_security_group.id')

# Delete the non-default SGs
VPC_SGs=$(ibmcloud is security-groups --json)
echo "$VPC_SGs" | jq -r '.[] | select (.vpc.name=="'${vpcname}'" and .id!="'$DEF_SG_ID'") | [.id,.name] | @tsv' | while read sgid sgname
do
    deleteRulesForSecurityGroupByID $sgid false
    echo "Deleting security group $sgname with id $sgid"
done    
echo "$VPC_SGs" | jq -r '.[] | select (.vpc.name=="'${vpcname}'" and .id!="'$DEF_SG_ID'") | [.id,.name] | @tsv' | while read sgid sgname
do
    echo "Deleting security group $sgname with id $sgid"
    deleteSecurityGroupByID $sgid true
done    


# Delete subnets
# 1) VPN gateways
# 2) Floating IPs
# 3) Subnets
# 4) Public gateways
ibmcloud is subnets --json | jq -r '.[] | select (.vpc.name=="'${vpcname}'") | [.id,.name,.public_gateway?.id] | @tsv' | while read subnetid subnetname pgid
do
    if [ $pgid ]; then
        export PG_IP_ID=$(ibmcloud is public-gateway $pgid --json | jq -r '.floating_ip.id')
        echo "Detaching public gateway from subnet"
        ibmcloud is subnet-public-gateway-detach $subnetid -f
        vpcGWDetached $subnetid
        # because multiple subnets could use the same gateway, we will clean up later
    fi
    ibmcloud is vpn-gateways --json | jq -r '.[] | select (.subnet.id=="'${subnetid}'") | [.id] | @tsv' | while read vpngwid
    do
        ibmcloud is vpn-gateway-delete $vpngwid -f
        vpcResourceDeleted vpn-gateway $vpngwid
    done
    echo "Deleting subnet with name $subnetname and id $subnetid"
    ibmcloud is subnet-delete $subnetid -f
    vpcResourceDeleted subnet $subnetid
done

# Delete public gateways
ibmcloud is public-gateways --json | jq -r '.[] | select (.vpc.name=="'${vpcname}'") | [.id,.name] | @tsv' | while read pgid pgname
do
    export PG_IP_ID=$(ibmcloud is public-gateway $pgid --json | jq -r '.floating_ip.id')
    echo "Deleting public gateway with id $pgid and name $pgname"
    ibmcloud is public-gateway-delete $pgid -f
    vpcResourceDeleted public-gateway $pgid
    #echo "Releasing IP address for public gateway"
    #ibmcloud is floating-ip-release $PG_IP_ID -f
    #vpcResourceDeleted floating-ip $PG_IP_ID
done

# Once the above is cleaned up, the VPC should be empty.
#
# Delete VPC
ibmcloud is vpcs --json | jq -r '.[] | select (.name=="'${vpcname}'") | .id' | while read vpcid
do
    echo "Deleting VPC ${vpcname} with id $vpcid"
    ibmcloud is vpc-delete $vpcid -f
    vpcResourceDeleted vpc $vpcid
done
