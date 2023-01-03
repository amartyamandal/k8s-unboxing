#!/bin/bash
source ./configure/functions/utility.sh
cpndcount=$(getndCount cp $1)
wrkndcount=$(getndCount wrk $1)
lbndcount=$(getndCount lb $1)

if [ -z "$2" ]
then
    if [ $cpndcount -gt 0 ]
    then
        ndops cp 'destroy --force'
    else
        echo "no control plane nodes eixsts for cluster with provider "$k8s_provider
    fi

    if [ $wrkndcount -gt 0 ]
    then
        if [ "$k8s_provider" = "libvirt" ]
        then
            for vm in $(virsh list | grep k8s-node | awk '{print $2}')
            do
                vm_name=$(echo "$vm" | tail -c 5)
                ndops wrk 'destroy --force' $vm_name
            done
        elif [ "$k8s_provider" = "virtualbox" ]
        then
            for vm in $(VBoxManage list vms | grep k8s-node | awk '{print $1}' | cut -c 2-29)
            do
                vm_name=$(echo "$vm" | tail -c 5)
                ndops wrk 'destroy --force' $vm_name
            done
        fi
    else
        echo "no worker nodes eixsts for cluster with provider "$k8s_provider
    fi

    if [ $lbndcount -gt 0 ]
    then
        ndops lb 'destroy --force'
    else
        echo "no lb node eixsts for cluster with provider "$k8s_provider
    fi
    rm -f .tmp/*.sh \
    .tmp/*.cfg \
    .tmp/hosts \
    .tmp/hosts.node \
    .tmp/wrknd_num.txt
elif [[ $2 == wrk ]]
then
    if [ $wrkndcount -gt 0 ]
    then
        if [[ $k8s_provider == "libvirt" ]]
        then
            for (( instance = 1; instance <= $3; ++instance )); do
                #echo "I m in the loop & deciding which one to remove"
                wrkndcntNow=$(getndCount wrk $1)
                VM_NAME=$(getvmToRemove)
                echo $VM_NAME
                vgVmName=$(echo $VM_NAME | tail -c 14)
                INET=$(run_rmComm 'wrk' $vgVmName 'ip address show eth0')
                #echo $INET
                ## VM_NAME=${PWD##*/}_k8s-node-$nd_indx
                if [ $wrkndcntNow -gt 1 ]
                then
                    kubectl drain $vgVmName --ignore-daemonsets --delete-local-data
                elif [ $wrkndcntNow -eq 1 ]
                then
                    echo "YOU CAN'T SAFELY DRAIN ONLY NODE IN YOU WORKER POOL! NOT DRAINING, BUT REMOVING ANYWAY!!"
                fi
                virsh shutdown --domain $VM_NAME
                sleep 20
                virsh undefine --domain $VM_NAME --remove-all-storage

                kubectl delete node $vgVmName

                INTERNAL_IP=$(echo $INET | sed -e 's/^.*inet //' -e 's/\/.*$//' | tr -d '\n')
                echo $INTERNAL_IP

                INTERNAL_MAC=$(echo $INET | grep -o -E '([[:xdigit:]]{1,2}:){5}[[:xdigit:]]{1,2}' | sed -n '1p')

                echo $INTERNAL_MAC

                rm -f .tmp/$vgVmName-routing.sh

                virsh net-update vagrant-libvirt delete ip-dhcp-host "<host mac='$INTERNAL_MAC' name='$vgVmName' ip='$INTERNAL_IP'/>" --live --config 
            done
        elif [[ $k8s_provider == "virtualbox" ]]
        then
            #ndops wrk 'destroy --force'
            for (( instance = 1; instance <= $3; ++instance )); do
                wrkndcntNow=$(getndCount wrk $1)
                VM_NAME=$(getvmToRemove)
                echo $VM_NAME
                vgVmName=$(echo $VM_NAME | tail -c 14)
                echo $vgVmName
                if [ $wrkndcntNow -gt 1 ]
                then
                    kubectl drain $vgVmName --ignore-daemonsets
                elif [ $wrkndcntNow -eq 1 ]
                then
                    echo "YOU CAN'T SAFELY DRAIN ONLY NODE IN YOU WORKER POOL! NOT DRAINING, BUT REMOVING ANYWAY!!"
                fi
                vbVM_NAME=$(VBoxManage list vms | grep $VM_NAME | awk '{print $1}' | cut -c 2-49)
                VBoxManage controlvm $vbVM_NAME poweroff
                VBoxManage unregistervm $vbVM_NAME  --delete

                kubectl delete node $vgVmName

                rm -f .tmp/$vgVmName-routing.sh
            done
        fi
    else
        echo "no worker nodes eixsts for cluster with provider "$k8s_provider
    fi
fi

