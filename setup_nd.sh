#!/bin/bash
source ./configure/functions/utility.sh

pcpcnt=$(getndCount cp $k8s_provider)
pwrkcnt=$(getndCount wrk $k8s_provider)
plbcnt=$(getndCount lb $k8s_provider)
finalndcnt=$node_nwrknd
requiredndcnt=0
if [[ $pcpcnt -gt 0 ]] && [ $plbcnt -gt 0 ] 
then
    echo "CP exists ..."
    
    if [[ $finalndcnt -gt $pwrkcnt ]]
    then
        requiredndcnt="$(($finalndcnt-$pwrkcnt))"
        echo "Scaling up by "$requiredndcnt
        ./scripts/setup-workers.sh $requiredndcnt
    elif [[ $finalndcnt -lt $pwrkcnt ]]
    then
        requiredndcnt="$(($pwrkcnt-$finalndcnt))"
        echo "Scaling down by "$requiredndcnt
        ./destroy.sh $k8s_provider wrk $requiredndcnt
    elif [[ $finalndcnt -eq $pwrkcnt ]]
    then
        echo "scaling not required"
        exit 1
    fi
    echo "present="$pwrkcnt "reuired="$requiredndcnt
    if [[ $pwrkcnt -eq 0 ]] && [[ $requiredndcnt -gt 0 ]]
    then
        echo "seeting up coredns & cni======================="
        ./scripts/setup-cni-plugin-dns.sh
    fi
else
    echo "CP do not exists operation can't proceed further..."
    exit 1
fi      
