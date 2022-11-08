#!/bin/bash
source ./configure/functions/utility.sh

for (( instance = 1; instance <= $1; ++instance )); do
  run_rmComm 'wrk' 'k8s-node-'$instance 'chmod +x configure-worker-master.sh;./configure-worker-master.sh' $1 
  run_rmComm 'wrk' 'k8s-node-'$instance 'chmod +x 'k8s-master-$instance'-routing.sh;./'k8s-master-$instance'-routing.sh' $1 
done

  