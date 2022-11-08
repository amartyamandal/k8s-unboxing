#!/bin/bash
source ./configure/functions/utility.sh

for (( instance = 1; instance <= $k8s_ncpnd; ++instance )); do
  copyFile 'cp' '.tmp/configure-controlplane.sh' '' 'k8s-master-'$instance
  run_rmComm 'cp' 'k8s-master-'$instance 'chmod +x configure-controlplane.sh;./configure-controlplane.sh'
done