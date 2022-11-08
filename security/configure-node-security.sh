#!/bin/bash
source ./configure/functions/utility.sh


for (( instance = 1; instance <= $1; ++instance )); do
    run_rmComm 'cp' 'k8s-master-'$instance 'rm secure_*.sh' $1
    copyFile 'cp' 'security/secure_cp_nd.sh' 'secure_cp_nd.sh' 'k8s-master-'$instance $1
    run_rmComm 'cp' 'k8s-master-'$instance 'chmod +x secure_cp_nd.sh;./secure_cp_nd.sh' $1
    if [[ "$3" == "default" ]]
    then
        echo "no cni specific security whitelisting for default option for cp nodes"
    elif [[ "$3" == "calico" ]]
    then
        echo "configure security for cni calico"
        copyFile 'cp' 'security/secure_cni_calico.sh' 'secure_cni_calico.sh' 'k8s-master-'$instance $1
        run_rmComm 'cp' 'k8s-master-'$instance 'chmod +x secure_cni_calico.sh;./secure_cni_calico.sh' $1
    elif [[ "$3" == "cilium" ]]
    then
        echo "no cni specific security whitelisting for cilium option for cp nodes"
    else
        echo "no cni specific security whitelisting"
    fi
done

for (( instance = 1; instance <= $2; ++instance )); do
    run_rmComm 'wrk' 'k8s-node-'$instance 'rm secure_*.sh' $2
    copyFile 'wrk' 'security/secure_wrkr_nd.sh' 'secure_wrkr_nd.sh' 'k8s-node-'$instance $2
    run_rmComm 'wrk' 'k8s-node-'$instance 'chmod +x secure_wrkr_nd.sh;./secure_wrkr_nd.sh' $2
    if [[ "$3" == "default" ]]
    then
        echo "no cni specific security whitelisting for default option for worker nodes"
    elif [[ "$3" == "calico" ]]
    then
        echo "configure security for cni calico"
        copyFile 'wrk' 'security/secure_cni_calico.sh' 'secure_cni_calico.sh' 'k8s-node-'$instance $2
        run_rmComm 'wrk' 'k8s-node-'$instance 'chmod +x secure_cni_calico.sh;./secure_cni_calico.sh' $2
    elif [[ "$3" == "cilium" ]]
    then
        echo "no cni specific security whitelisting for cilium option for worker nodes"
    else
        echo "no cni specific security whitelisting"
    fi
done
run_rmComm 'lb' 'k8s-lb' 'rm secure_*.sh'
copyFile 'lb' 'security/secure_lb.sh' 'secure_lb.sh' 'k8s-lb'
run_rmComm 'lb' 'k8s-lb' 'chmod +x secure_lb.sh;./secure_lb.sh'



