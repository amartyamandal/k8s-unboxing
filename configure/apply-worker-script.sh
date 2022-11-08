#!/bin/bash
source ./configure/functions/utility.sh

for (( instance = 1; instance <= $k8s_nwrknd; ++instance )); do
    run_rmComm 'wrk' 'k8s-node-'$instance 'chmod +x configure-worker.sh;./configure-worker.sh' 
    if [[ $k8s_cni == "default" ]]
    then
      echo "configure manual routing"
      run_rmComm 'wrk' 'k8s-node-'$instance 'chmod +x k8s-node-'$instance'-routing.sh;./k8s-node-'$instance'-routing.sh' 
    fi
done


  