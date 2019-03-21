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


# To delete virtual machine instances
# 1) Delete the network interfaces
# 2) Delete the machines (VSIs)

# Obtain all instances for VPC
export VSI_IDs=$(ibmcloud is instances --json |\
       jq -c '[.[] | select (.vpc.name=="'${vpcname}'") | {id: .id, name: .name}]')


echo "$VSI_IDs" | jq -c -r '.[] | [.id] | @tsv' | while read vsiid
do
    #echo "$vsiid / $nicid"
    ibmcloud is instance-network-interfaces $vsiid --json | jq -r '.[] | [.id,.floating_ips[]?.id] | @tsv' | while read nicid ipid 
    do
        if [ $ipid ]; then
            echo "Deleting floating IP with id $ipid for NIC with id $nicid"
            ibmcloud is instance-network-interface-floating-ip-remove $vsiid $nicid $ipid -f
            vpcResourceDeleted instance-network-interface-floating-ip $vsiid $nicid $ipid
            ibmcloud is floating-ip-release $ipid -f
        fi
    done
done


# Loop over VSIs again to delete them
echo "$VSI_IDs" | jq -c -r '.[] | [.id,.name] | @tsv ' | while read vsiid name
do
    echo "Deleting VSI $name with id $vsiid"
    ibmcloud is instance-delete $vsiid -f
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

export DEF_SG=$(ibmcloud is vpcs --json | jq -r '.[] | select (.name=="'${vpcname}'") | .default_security_group.id')

# Delete rules for non-default SGs
ibmcloud is security-groups --json | jq -r '.[] | select (.vpc.name=="'${vpcname}'" and .id!="'$DEF_SG'") | [.id,.name] | @tsv' | while read sgid sgname
do
    ibmcloud is security-group-rules $sgid --json | jq -r '.[].id' | while read ruleid
    do
        echo "Deleting rule under $sgname"
        ibmcloud is security-group-rule-delete $sgid $ruleid -f
        vpcResourceDeleted security-group-rule $sgid $ruleid
    done
done    

# Delete the non-default SGs
ibmcloud is security-groups --json | jq -r '.[] | select (.vpc.name=="'${vpcname}'" and .id!="'$DEF_SG'") | [.id,.name] | @tsv' | while read sgid sgname
do
    echo "Deleting security group $sgname with id $sgid"
    ibmcloud is security-group-delete $sgid -f
    vpcResourceDeleted security-group $sgid
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
