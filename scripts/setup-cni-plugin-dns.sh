#!/bin/bash

source ./configure/functions/utility.sh
delNs calico-system

corednsresource=$(kubectl get pod -A | grep coredns -c)
if [ $corednsresource -gt 0 ]
then
    kubectl delete -f ./dns/coredns/coredns-1.8.yaml
fi

ciliumresource=$(kubectl get pod -A | grep cilium -c)
if [ $ciliumresource -gt 0 ]
then
    cilium uninstall
fi
calicoresource=$(kubectl get ns | grep calico-system -c)
if [ $calicoresource -gt 0 ]
then
    kubectl delete -f ./cni/calico/custom-resources.yaml
    kubectl delete -f https://raw.githubusercontent.com/projectcalico/calico/v3.24.1/manifests/tigera-operator.yaml
fi
if [[ $k8s_cni == "calico" ]]
then
  echo "setup calico..."
  kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.24.1/manifests/tigera-operator.yaml

  sleep 20
  kubectl create -f ./cni/calico/custom-resources.yaml
elif [[ $k8s_cni == "cilium" ]]
then
  echo "setup cilium..."
  cilium install
  cilium status --wait
  #cilium connectivity test  
else
  echo "no 3rd party CNI configured, but simple routing.."
fi

if [ $corednsresource -eq 0 ]
then
    echo "Installing coredns...."
    kubectl apply -f ./dns/coredns/coredns-1.8.yaml
fi



# kubectl delete -f https://raw.githubusercontent.com/projectcalico/calico/v3.24.1/manifests/tigera-operator.yaml
# kubectl delete -f ./cni/calico/custom-resources.yaml
# kubectl delete -f ./dns/coredns/coredns-1.8.yaml