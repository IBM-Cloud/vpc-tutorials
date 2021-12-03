# Some common load balancer scripting functions
#
# (C) 2019 IBM
#
# Written by Vidyasagar Machupalli


function vpcLoadBalancerLoop {
    echo "... waiting for $3 of $2 to be $1"
    until ibmcloud is $2 --output json | jq -c --exit-status '.[] | select (.name=="'$3'" and .provisioning_status=="'$1'")' >/dev/null
    do
        sleep 10
    done
    echo "$2 now $1"
}

function vpcLBResourceLoop {
    echo "... waiting for $3 of $2 to be $1"
    until ibmcloud is $2 $4 --output json | jq -c --exit-status '.[] | select (.name=="'$3'" and .provisioning_status=="'$1'")' >/dev/null
    do
        sleep 10
    done
    echo "$3 now $1"
}

function vpcLBPoolMemberLoop {
    echo "... waiting for $5 of $2 to be $1"
    until ibmcloud is $2 $3 $4 --output json | jq -c --exit-status '.[] | select (.id=="'$5'" and .provisioning_status=="'$1'")' >/dev/null
    do
        sleep 10
    done
    echo "$5 now $1"
}

function vpcLBListenerLoop {
    echo "... waiting for $4 of $2 to be $1"
    until ibmcloud is $2 $3 --output json | jq -c --exit-status '.[] | select (.id=="'$4'" and .provisioning_status=="'$1'")' >/dev/null
    do
        sleep 10
    done
    echo "$4 now $1"
}

function vpcResourceActive {
    vpcLoadBalancerLoop active $1 $2
}

function vpcLBResourceActive {
    vpcLBResourceLoop active $1 $2 $3
}

function vpcLBMemberActive {
    vpcLBPoolMemberLoop active $1 $2 $3 $4
}

function vpcLBListenerActive {
    vpcLBListenerLoop active $1 $2 $3
}
