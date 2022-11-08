#!/bin/bash
source ./configure/functions/utility.sh

echo "configuring control plane..."
cp templates/configure-controlplane.sh.template .tmp/configure-controlplane.sh


KUBERNETES_LB_IP="$(getIP 'lb')"
sed -i 's/$KUBERNETES_LB_PUBLIC_ADDRESS/'$KUBERNETES_LB_IP'/g' .tmp/configure-controlplane.sh
etcd_servers=""
for (( instance = 1; instance <= $k8s_ncpnd; ++instance )); do
  INTERNAL_IP="$(getIP 'cp' 'k8s-master-'$instance)"
  if [ $instance = $k8s_ncpnd ]
  then
    etcd_servers+="https://$INTERNAL_IP:2379"
  else
    etcd_servers+="https://$INTERNAL_IP:2379,"
  fi
  for kube_binary in kube-apiserver kube-controller-manager kube-scheduler kubectl; do 
		copyFile 'cp' '.tmp/k8s_'$k8s_V'/'$kube_binary $kube_binary 'k8s-master-'$instance
	done 
done
echo $etcd_servers
sed -i "s~@ETCD_SERVERS@~$etcd_servers~g" .tmp/configure-controlplane.sh
sed -i "s~@APISERVER_COUNT@~$k8s_ncpnd~g" .tmp/configure-controlplane.sh

default_network_interface=$(getIface)
sed -i "s~@default_network_interface@~$default_network_interface~g" .tmp/configure-controlplane.sh