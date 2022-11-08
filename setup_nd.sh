#!/bin/bash
source ./configure/functions/utility.sh

cpcount=$(getndCount cp $k8s_provider)
wrkcount=$(getndCount wrk $k8s_provider)
lbcount=$(getndCount lb $k8s_provider)

if [[ $cpcount -gt 0 ]] && [ $lbcount -gt 0 ] && [ $wrkcount -eq 0 ]
then
    ./scripts/setup-workers.sh
    sleep 10
    ./setup_end.sh
    ./scripts/setup-cni-plugin-dns.sh
elif [[ $cpcount -gt 0 ]] && [ $lbcount -gt 0 ] && [ $wrkcount -gt 0 ]
then
    if [ -z "$1" ]
    then
        echo "Cluster Exists, worker nodes exists, use scale to scale out or in"
    elif [[ $1 == redo ]]
    then
        ./destroy.sh $k8s_provider wrk
        sleep 30
        ./scripts/setup-workers.sh
        sleep 10
        ./scripts/setup-cni-plugin-dns.sh
    fi
else
    echo "no controlplan exists"
fi