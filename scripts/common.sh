# Some common scripting functions
#
# (C) 2019 IBM
#
# Written by Henrik Loeser, hloeser@de.ibm.com


# Loop until a certain resource is in the expected state
function vpcResourceLoop {
    echo "... waiting for $3 of $2 to be $1"
    until ibmcloud is $2 --json | jq -c --exit-status '.[] | select (.name=="'$3'" and .status=="'$1'")' >/dev/null
    do
        sleep 10
    done        
    echo "$2 now $1"
}

# Wrapper to check availability
function vpcResourceAvailable {
    vpcResourceLoop available $1 $2
}

# Wrapper to check resource is running
function vpcResourceRunning {
    vpcResourceLoop running $1 $2
}

# Look up the current resource group
function currentResourceGroup {
    ibmcloud target | grep "Resource group:" | awk '{print $3}'
}

# Split string of SSH key names up, look up their UUIDs
# and pass the UUIDs back as single, comma-delimited string
function SSHKeynames2UUIDs {
    SSHKeys=$(ibmcloud is keys --json)
    keynames=$1
    keys=()
    while [ "$keynames" ] ;do
        iter=${keynames%%,*}
        keys+=($(echo $SSHKeys | jq -r '.[] | select (.name=="'$iter'") | .id'))
        [ "$keynames" = "$iter" ] && \
        keynames='' || \
        keynames="${keynames#*,}"
    done
    printf -v res_keys "%s," "${keys[@]}"
    res_keys=${res_keys%?}
    echo "$res_keys"
}