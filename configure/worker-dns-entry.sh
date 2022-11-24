#!/bin/bash
source ./configure/functions/utility.sh
if [ -z "$1" ]
then
    echo "Operation can not be performed"
    exit 1
fi

if [ "$k8s_provider" = "libvirt" ]
then
    INET=$(run_rmComm 'wrk' 'k8s-node-'$1 'ip address show eth0')
    INTERNAL_IP=$(echo $INET |grep 'inet '| sed -e 's/^.*inet //' -e 's/\/.*$//' | tr -d '\n')
    echo k8s-node-$1 $INTERNAL_IP

    INTERNAL_MAC=$(echo $INET | grep -o -E '([[:xdigit:]]{1,2}:){5}[[:xdigit:]]{1,2}' | sed -n '1p')

    echo $1 $INTERNAL_MAC

    virsh net-update vagrant-libvirt add ip-dhcp-host "<host mac='$INTERNAL_MAC' name='k8s-node-$1' ip='$INTERNAL_IP'/>" --live --config 
fi
