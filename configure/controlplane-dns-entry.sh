#!/bin/bash
source ./configure/functions/utility.sh
if [ "$k8s_provider" = "libvirt" ]
then
    for (( instance = 1; instance <= $k8s_ncpnd; ++instance )); do
        INET=$(run_rmComm 'cp' 'k8s-master-'$instance 'ip address show eth0')
        echo $INET
        INTERNAL_IP=$(echo $INET |grep 'inet '| sed -e 's/^.*inet //' -e 's/\/.*$//' | tr -d '\n')
        
        echo k8s-master-$instance $INTERNAL_IP

        INTERNAL_MAC=$(echo $INET | grep -o -E '([[:xdigit:]]{1,2}:){5}[[:xdigit:]]{1,2}' | sed -n '1p')

        echo k8s-master-$instance $INTERNAL_MAC

        virsh net-update vagrant-libvirt add ip-dhcp-host "<host mac='$INTERNAL_MAC' name='k8s-master-$instance' ip='$INTERNAL_IP'/>" --live --config 
    done
    ##########################################################
    INET=$(run_rmComm 'lb' 'k8s-lb' 'ip address show eth0')
    echo $INET
    INTERNAL_IP=$(echo $INET |grep 'inet '| sed -e 's/^.*inet //' -e 's/\/.*$//' | tr -d '\n')
    echo "k8s-lb "$INTERNAL_IP
    INTERNAL_MAC=$(echo $INET | grep -o -E '([[:xdigit:]]{1,2}:){5}[[:xdigit:]]{1,2}' | sed -n '1p')
    echo "k8s-lb "$INTERNAL_MAC
    virsh net-update vagrant-libvirt add ip-dhcp-host "<host mac='$INTERNAL_MAC' name='k8s-lb' ip='$INTERNAL_IP'/>" --live --config 
    ##############################################################
fi

