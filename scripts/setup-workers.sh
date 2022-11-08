#!/bin/bash 
source ./configure/functions/utility.sh
#ndops wrk 'global-status --prune'
ndops wrk up
echo "calling configure-hosts-worker-script.sh========================="
./configure/configure-hosts-worker-script.sh
echo "calling worker-dns-entry.sh========================="
./configure/worker-dns-entry.sh


echo "Configure k8s workers install script..."

echo "calling configure-worker-script.sh========================="
./configure/configure-worker-script.sh

# #./configure/configure-worker-master-script.sh $1 $2 $4
echo "calling apply-worker-script.sh========================="
./configure/apply-worker-script.sh

#./configure/apply-worker-master-script.sh $1
    

