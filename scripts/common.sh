# Some common scripting functions
#
# (C) 2019 IBM
#
# Written by Henrik Loeser, hloeser@de.ibm.com

function vpcResourceAvailable {
    until ibmcloud is $1 --json | jq -c '.[] | select (.name=="'$2'" and .status=="available") | [.status,.name]' > /dev/null
    do
        sleep 10
    done        
    echo "$2 became available"
}

function currentResourceGroup {
    ibmcloud target | grep "Resource group:" | awk '{print $3}'
}