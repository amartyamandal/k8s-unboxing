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
    fi

    if [ $wrkndcount -gt 0 ]
    then
        ndops wrk 'destroy --force'
    fi

    if [ $lbndcount -gt 0 ]
    then
        ndops lb 'destroy --force'
    fi
    rm -f .tmp/*.sh \
    .tmp/*.cfg \
    .tmp/*.xml \
    .tmp/hosts \
    .tmp/hosts.node
elif [[ $2 == wrk ]]
then
    if [ $wrkndcount -gt 0 ]
    then
        kubectl delete -f https://storage.googleapis.com/kubernetes-the-hard-way/coredns-1.8.yaml
        ciliumresource=$(kubectl get pod -A | grep cilium -c)
        if [ $ciliumresource -gt 0 ]
        then
            #kubectl --namespace kube-system delete ds cilium
            cilium uninstall
        fi
        calicoresource=$(kubectl get ns | grep calico-system -c)
        if [ $calicoresource -gt 0 ]
        then
            kubectl delete -f ./cni/calico/custom-resources.yaml
            kubectl delete -f https://raw.githubusercontent.com/projectcalico/calico/v3.24.1/manifests/tigera-operator.yaml
        fi
        if [[ $k8s_provider == "libvirt" ]]
        then
            for (( instance = 1; instance <= $k8s_nwrknd; ++instance )); do
                INET=$(run_rmComm 'wrk' 'k8s-node-'$instance 'ip address show eth0')
                VM_NAME=${PWD##*/}_k8s-node-$instance
                virsh shutdown --domain $VM_NAME
                sleep 20
                virsh undefine --domain $VM_NAME --remove-all-storage

                INTERNAL_IP=$(echo $INET | sed -e 's/^.*inet //' -e 's/\/.*$//' | tr -d '\n')
                echo $INTERNAL_IP

                INTERNAL_MAC=$(echo $INET | grep -o -E '([[:xdigit:]]{1,2}:){5}[[:xdigit:]]{1,2}' | sed -n '1p')

                echo $INTERNAL_MAC

                virsh net-update vagrant-libvirt delete ip-dhcp-host "<host mac='$INTERNAL_MAC' name='k8s-node-$instance' ip='$INTERNAL_IP'/>" --live --config 
            done
        elif [[ $k8s_provider == "virtualbox" ]]
        then
            ndops wrk 'destroy --force'
        fi
    fi
fi

