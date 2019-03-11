# Some common scripting functions
#
# (C) 2019 IBM
#
# Written by Henrik Loeser, hloeser@de.ibm.com

function vpcResourceLoop {
    echo wait for $3 of $2 to be $1
    until ibmcloud is $2 --json | jq -c --exit-status '.[] | select (.name=="'$3'" and .status=="'$1'")' >/dev/null
    do
        sleep 10
    done        
    echo "$2 now $1"
}
function vpcResourceAvailable {
    vpcResourceLoop available $1 $2
}
function vpcResourceRunning {
    vpcResourceLoop running $1 $2
}

function currentResourceGroup {
    ibmcloud target | grep "Resource group:" | awk '{print $3}'
}
