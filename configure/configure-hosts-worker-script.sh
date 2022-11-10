#!/bin/bash
source ./configure/functions/utility.sh

sudo cp /etc/hosts /etc/hosts.bkup
sudo cp templates/hosts.template /etc/hosts
sudo cp templates/hosts.node.template .tmp/hosts.node

CPHOSTS=""
for (( instance = 1; instance <= $k8s_ncpnd; ++instance )); do
    INTERNAL_IP="$(getIP 'cp' 'k8s-master-'$instance)"
    echo $INTERNAL_IP

    CPHOSTS+="$INTERNAL_IP k8s-master-$instance.$k8s_domain\n"
done
sudo sed -i "s/@CPHOSTS@/$CPHOSTS/g" /etc/hosts
sudo sed -i "s/@DOMAIN@/$k8s_domain/g" /etc/hosts

sudo sed -i "s/@CPHOSTS@/$CPHOSTS/g" .tmp/hosts.node
sudo sed -i "s/@DOMAIN@/$k8s_domain/g" .tmp/hosts.node


INTERNAL_LB_IP="$(getIP 'lb')"
echo $INTERNAL_LB_IP

sudo sed -i 's/k8s-lb-ip/'$INTERNAL_LB_IP'/g' /etc/hosts
sudo sed -i 's/k8s-lb-ip/'$INTERNAL_LB_IP'/g' .tmp/hosts.node

WRKHOSTS=""
for (( instance = 1; instance <= $k8s_nwrknd; ++instance )); do
    INTERNAL_IP="$(getIP 'wrk' 'k8s-node-'$instance)"
    echo $INTERNAL_IP
    WRKHOSTS+="$INTERNAL_IP k8s-node-$instance.$k8s_domain\n"
done
sudo sed -i "s/@WRKHOSTS@/$WRKHOSTS/g" /etc/hosts
sudo sed -i "s/@WRKHOSTS@/$WRKHOSTS/g" .tmp/hosts.node
sudo cp /etc/hosts .tmp/hosts

for (( instance = 1; instance <= $k8s_ncpnd; ++instance )); do
    copyFile 'cp' '.tmp/hosts.node' 'hosts' 'k8s-master-'$instance
    run_rmComm 'cp' 'k8s-master-'$instance 'sudo cp /etc/hosts /etc/hosts.bkup;sudo cp hosts /etc/hosts'
done

for (( instance = 1; instance <= $k8s_nwrknd; ++instance )); do
    copyFile 'wrk' '.tmp/hosts.node' 'hosts' 'k8s-node-'$instance
    run_rmComm 'wrk' 'k8s-node-'$instance 'sudo cp /etc/hosts /etc/hosts.bkup;sudo cp hosts /etc/hosts'
done

copyFile 'lb' '.tmp/hosts.node' 'hosts' 'k8s-lb'
run_rmComm 'lb' 'k8s-lb' 'sudo cp /etc/hosts /etc/hosts.bkup;sudo cp hosts /etc/hosts'

