#!/bin/bash
source ./configure/functions/utility.sh

cpcount=$(getndCount cp $k8s_provider)
wrkcount=$(getndCount wrk $k8s_provider)
lbcount=$(getndCount lb $k8s_provider)

if [[ $cpcount -gt 0 ]] && [ $lbcount -gt 0 ]
then
    echo "control plane exists, destroy cluster to re-build"
    exit 1
elif [[ $cpcount -eq 0 ]]
then
    ./scripts/setup-controlplane.sh
fi
