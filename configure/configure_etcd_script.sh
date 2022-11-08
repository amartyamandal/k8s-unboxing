#!/bin/bash
source ./configure/functions/utility.sh

for (( instance = 1; instance <= $k8s_ncpnd; ++instance )); do
  run_rmComm 'cp' 'k8s-master-'$instance 'rm -rf certs kubeconfigs'
done
cp templates/configure-etcd.sh.template .tmp/configure-etcd.sh
echo "Distributing ca.pem, ca-key.pem, kubernetes-key.pem, kubernetes.pem,"
echo "service-account-key.pem service-account.pem certificates to all master nodes..."
echo "Distributing all the Kubernetes Configuration Files to all the master nodes"


initial_clusters=""
for (( instance = 1; instance <= $k8s_ncpnd; ++instance )); do
  run_rmComm 'cp' 'k8s-master-'$instance 'mkdir certs'
  for key in certs/ca/ca.pem certs/ca/ca-key.pem certs/apiserver/kubernetes-key.pem certs/apiserver/kubernetes.pem certs/svca/service-account-key.pem certs/svca/service-account.pem; do
    cert_name=$(echo ${key} | cut -d"/" -f3)
    copyFile 'cp' ${key} 'certs/${cert_name}' 'k8s-master-'$instance
  done


  run_rmComm 'cp' 'k8s-master-'$instance 'mkdir kubeconfigs'
  for kubeconfig in kubeconfig/admin/admin.kubeconfig kubeconfig/kubecntrl/kube-controller-manager.kubeconfig kubeconfig/schedulerclient/kube-scheduler.kubeconfig kubeconfig/encryption-config.yaml; do 
		config_name=$(echo ${kubeconfig} | cut -d"/" -f3)
    copyFile 'cp' ${kubeconfig} 'kubeconfigs/${config_name}' 'k8s-master-'$instance
	done 



  echo "Configuring etcd..."


  INTERNAL_IP="$(getIP 'cp' 'k8s-master-'$instance)"
  
 
  if [ $instance = $k8s_ncpnd ]
  then
    initial_clusters+="k8s-master-${instance}=https://$INTERNAL_IP:2380" 
  else
    initial_clusters+="k8s-master-${instance}=https://$INTERNAL_IP:2380," 
  fi


done
echo $initial_clusters

sed -i "s~@INITIAL_CLUSTERS@~$initial_clusters~g" .tmp/configure-etcd.sh

default_network_interface=$(getIface)

sed -i "s~@default_network_interface@~$default_network_interface~g" .tmp/configure-etcd.sh