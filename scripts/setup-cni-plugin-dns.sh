#!/bin/bash

source ./configure/functions/utility.sh
delNs calico-system
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
echo "Installing coredns...."
kubectl apply -f ./dns/coredns/coredns-1.8.yaml




# kubectl delete -f https://raw.githubusercontent.com/projectcalico/calico/v3.24.1/manifests/tigera-operator.yaml
# kubectl delete -f ./cni/calico/custom-resources.yaml
# kubectl delete -f ./dns/coredns/coredns-1.8.yaml