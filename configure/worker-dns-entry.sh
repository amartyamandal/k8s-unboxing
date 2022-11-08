#!/bin/bash
source ./configure/functions/utility.sh
if [ "$k8s_provider" = "libvirt" ]
then
    for (( instance = 1; instance <= $k8s_nwrknd; ++instance )); do
        INET=$(run_rmComm 'wrk' 'k8s-node-'$instance 'ip address show eth0')
        INTERNAL_IP=$(echo $INET |grep 'inet '| sed -e 's/^.*inet //' -e 's/\/.*$//' | tr -d '\n')
        echo k8s-node-$instance $INTERNAL_IP

        INTERNAL_MAC=$(echo $INET | grep -o -E '([[:xdigit:]]{1,2}:){5}[[:xdigit:]]{1,2}' | sed -n '1p')

        echo $instance $INTERNAL_MAC

        virsh net-update vagrant-libvirt add ip-dhcp-host "<host mac='$INTERNAL_MAC' name='k8s-node-$instance' ip='$INTERNAL_IP'/>" --live --config 
    done
fi
