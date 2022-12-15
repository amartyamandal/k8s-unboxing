#!/bin/bash 
source ./configure/functions/utility.sh
req_nd=0
if [ -z "$1" ]
then
    req_nd=1
else
    req_nd=$1
fi
declare -a newnd_array=()

thirdOctate=0
if [[ "$k8s_cni" == "default" ]]
then
    thirdOctate=$(getThirdOctate)
fi
j=$thirdOctate
for (( instance = 1; instance <= $req_nd; ++instance )); do
    #ndops wrk 'global-status --prune'
    node_num=$((1000 + RANDOM % 999))
    ndops wrk up $node_num
    echo "calling worker-dns-entry.sh========================="
    ./configure/worker-dns-entry.sh $node_num
    echo "calling configure-worker-script.sh========================="
    ./configure/configure-worker-script.sh $node_num
    node=$(echo k8s-node-$node_num)
    newnd_array+=("$node")
    if [[ "$k8s_cni" == "default" ]]
    then
        #echo k8s-node-$node_num
        #node=$(echo k8s-node-$node_num)
        pod_cidr=10.200.$j.0/24
        echo "POD CIDR for node "$node
        echo $pod_cidr
        echo $pod_cidr | cat >.tmp/pod_cidr.txt
        echo "Copy pod_cidr text"
        copyFile 'wrk' '.tmp/pod_cidr.txt' '' $node 
        echo "Remove pod_cidr.txt from tmp folder"
        rm .tmp/pod_cidr.txt
        j=$(($j+1))
    fi
done

echo "calling configure-hosts-worker-script.sh========================="
./configure/configure-hosts-worker-script.sh
if [[ "$k8s_cni" == "default" ]]
then
    echo "calling cni_default.sh========================="
    ./configure/cni_default.sh
else
  echo "No routing configured, it will be configured during CNI configurations"
fi
for newnd in "${newnd_array[@]}"
do
     echo "calling apply-worker-script.sh on $newnd ========================="
    ./configure/apply-worker-script.sh $newnd
done



    

