#!/bin/bash
source ./configure/functions/utility.sh

pcpcnt=$(getndCount cp $k8s_provider)
pwrkcnt=$(getndCount wrk $k8s_provider)
plbcnt=$(getndCount lb $k8s_provider)
finalndcnt=$k8s_nwrknd

if [[ $pcpcnt -gt 0 ]] && [ $plbcnt -gt 0 ] 
then
    echo "CP exists ..."
    requiredndCount=0
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
        requiredndcnt=0
        echo "scaling not required"
        exit 1
    fi
    if [[ $pwrkcnt -eq 0 ]] && [[ $requiredndCount -gt 0 ]]
    then
        ./scripts/setup-cni-plugin-dns.sh
    fi
else
    echo "CP do not exists operation can't proceed further..."
    exit 1
fi      
