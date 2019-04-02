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

# Wait for a resource to be fully deleted
# Check that it is still present until the check fails.
# The check times out after 25 * 20 seconds.
function vpcResourceDeleted {
    COUNTER=0
    while ibmcloud is $1 $2 $3 $4 > /dev/null 2>/dev/null
    do
        echo "... waiting for $1 $2 $3 $4 to fail indicating it has been deleted"
        sleep 20
        let COUNTER=COUNTER+1
        if [ $COUNTER -gt 25 ]; then
            echo "timeout"
            exit
        fi
    done
    echo "$1 $2 $3 $4 went away"
}


function vpcLBDeleted {
    COUNTER=0
    INTERIM_RESULT="DELETING"
    INTERIM_RESULTREQ="DELETING"
    #echo "RESULT 1: $INTERIM_RESULT"
    #echo "RESULT REQ1: $INTERIM_RESULTREQ"
    while [ "$INTERIM_RESULT" != "DELETED" ] && [ "$INTERIM_RESULTREQ" != "DELETED" ] 
    #until ibmcloud is $1 $2 $3 $4 -f | awk 'NR==3' | grep -q "cannot be found" && echo "DELETED" || echo "DELETING..." == "DELETED"
    do
        echo "... waiting for ${1/-delete/} $2 $3 $4 to fail indicating it has been deleted"
        OUTPUT=$(ibmcloud is $1 $2 $3 $4 -f)
        #echo "OUTPUT: $OUTPUT"
        RESULT=$(echo "$OUTPUT" | awk 'NR==3' | grep -q "cannot be found" && echo "DELETED" || echo "DELETING")
        RESULTREQ=$(echo "$OUTPUT" | awk 'NR==2' | grep -q "are required" && echo "DELETED" || echo "DELETING")
        export INTERIM_RESULT=$RESULT
        export INTERIM_RESULTREQ=$RESULTREQ
        # echo "RESULT 1: $INTERIM_RESULT"
        # echo "RESULT REQ1: $INTERIM_RESULTREQ"
        sleep 20
        let COUNTER=COUNTER+1
        if [ $COUNTER -gt 25 ]; then
            echo "timeout"
            exit
        fi
    done
    echo "${1/-delete/} $2 $3 $4 went away"
}

function vpcGWDetached {
    until ibmcloud is subnet $1 --json | jq -r '.public_gateway==null' > /dev/null
    do
        echo "waiting"
        sleep 10
    done
    sleep 20
    echo "GW detached"
}

#
