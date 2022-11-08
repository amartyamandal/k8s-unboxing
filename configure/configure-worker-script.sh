#!/bin/bash

source ./configure/functions/utility.sh

certpath=$(pwd)/certs
rm .tmp/k8s-node-*-routing.sh 
rm -rf certs/wrknodes kubeconfig/wrknodes
mkdir -p certs/wrknodes
mkdir -p kubeconfig/wrknodes
LB_IP_ADDRESS="$(getIP 'lb')"


cp templates/configure-worker.sh.template .tmp/configure-worker.sh
#sed -i 's/@CONTD_V@/'$k8s_CONTD_V'/g' .tmp/configure-worker.sh
sed -i 's/@k8s_cni@/'$k8s_cni'/g' .tmp/configure-worker.sh

j=0
##big loop###################################
for (( instance = 1; instance <= $k8s_nwrknd; ++instance )); do

  run_rmComm 'wrk' 'k8s-node-'$instance 'rm -rf ./*'
  if [[ $k8s_cni == "default" ]]
  then
    pod_cidr=10.200.$j.0/24
    echo $pod_cidr | cat >.tmp/pod_cidr.txt
    echo "Copy pod_cidr text"
    copyFile 'wrk' '.tmp/pod_cidr.txt' '' 'k8s-node-'$instance 
    echo "Remove pod_cidr.txt from tmp folder"
    rm .tmp/pod_cidr.txt
    
    # sed -i "s|POD_CIDR_IP|$pod_cidr|g" .tmp/configure-worker.sh
    j=$(($j+1))
  fi
echo "Copy configure-worker.sh"
copyFile 'wrk' '.tmp/configure-worker.sh' '' 'k8s-node-'$instance 
##The Kubelet Client Certificates============================
echo "Generating The Kubelet Client Certificates for worker node "k8s-node-${instance}

cat > certs/wrknodes/k8s-node-${instance}-csr.json <<EOF
{
  "CN": "system:node:k8s-node-${instance}",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "CAN",
      "L": "Toronto",
      "O": "system:nodes",
      "OU": "Kubernetes The Hard Way",
      "ST": "Ontario"
    }
  ]
}
EOF

  NODE_IP="$(getIP 'wrk' 'k8s-node-'$instance)"
  cfssl gencert -ca=$certpath/ca/ca.pem -ca-key=$certpath/ca/ca-key.pem -config=$certpath/ca/ca-config.json -hostname=k8s-node-${instance},${NODE_IP} -profile=kubernetes certs/wrknodes/k8s-node-${instance}-csr.json | cfssljson -bare certs/wrknodes/k8s-node-${instance}

  sleep 5

  echo "Generate a kubeconfig files for worker node "k8s-node-${instance}
  



  run_rmComm 'wrk' 'k8s-node-'$instance 'mkdir certs;mkdir kubeconfigs'
  echo "Generate a kubeconfig file for "k8s-node-${instance}
  #--server=https://${KUBERNETES_PUBLIC_ADDRESS}:6443 \
  kubectl config set-cluster kubernetes-the-hard-way \
    --certificate-authority=certs/ca/ca.pem \
    --embed-certs=true \
    --server=https://${LB_IP_ADDRESS}:6443 \
    --kubeconfig=kubeconfig/wrknodes/k8s-node-${instance}.kubeconfig

  kubectl config set-credentials system:node:k8s-node-${instance} \
    --client-certificate=certs/wrknodes/k8s-node-${instance}.pem \
    --client-key=certs/wrknodes/k8s-node-${instance}-key.pem \
    --embed-certs=true \
    --kubeconfig=kubeconfig/wrknodes/k8s-node-${instance}.kubeconfig

  kubectl config set-context default \
    --cluster=kubernetes-the-hard-way \
    --user=system:node:k8s-node-${instance} \
    --kubeconfig=kubeconfig/wrknodes/k8s-node-${instance}.kubeconfig

  kubectl config use-context default --kubeconfig=kubeconfig/wrknodes/k8s-node-${instance}.kubeconfig


  echo "Copying kubelet client certificates& ca to worker node "k8s-node-${instance}
 

  
  for key in certs/wrknodes/k8s-node-${instance}-key.pem certs/wrknodes/k8s-node-${instance}.pem certs/ca/ca.pem; do 
    cert_name=$(echo ${key} | cut -d"/" -f3)
    echo $cert_name
    copyFile 'wrk' $key 'certs/'$cert_name 'k8s-node-'$instance 
    
  done

  echo "Distribute the Kubernetes Configuration Files to worker node "k8s-node-${instance}
 

  for kubeconfig in kubeconfig/wrknodes/k8s-node-${instance}.kubeconfig kubeconfig/prxy/kube-proxy.kubeconfig; do
    config_name=$(echo ${kubeconfig} | cut -d"/" -f3)
    copyFile 'wrk' $kubeconfig 'kubeconfigs/'$config_name 'k8s-node-'$instance
  done

  for kube_binary in kubectl kube-proxy kubelet; do 
		copyFile 'wrk' '.tmp/k8s_'$k8s_V'/'$kube_binary $kube_binary 'k8s-node-'$instance
	done 
  ################## need to change later ########################
  copyFile 'wrk' '.tmp/crictl_'$k8s_CRI_CTL_V'/crictl' '' 'k8s-node-'$instance
  copyFile 'wrk' '.tmp/runc_'$k8s_RUNC_V'/runc' '' 'k8s-node-'$instance
  copyFile 'wrk' '.tmp/contd_'$k8s_CONTD_V 'containerd' 'k8s-node-'$instance
  copyFile 'wrk' '.tmp/cni_'$k8s_CNI_PLUGIN_V 'cni_plugin' 'k8s-node-'$instance
done 

if [[ "$k8s_cni" == "default" ]]
then
  for (( node = 1; node <= $k8s_nwrknd; ++node )); do
      cat << EOF >> .tmp/k8s-node-$node-routing.sh
  #!/bin/bash
EOF
      echo "Creating k8s-node-$node-routing.sh ========================"
      for (( instance = 1; instance <= $k8s_nwrknd; ++instance )); do
          if [ $instance -ne $node ]
          then
              echo "Present-node-k8s-node-$instance"
              node_internal_ip="$(getIP 'wrk' 'k8s-node-'$instance)"
              echo $node_internal_ip
              pod_cidr=$(run_rmComm 'wrk' 'k8s-node-'$instance 'cat pod_cidr.txt')
              echo "POD CIDR"
              echo $pod_cidr
              echo "ip route add $pod_cidr via $node_internal_ip"
              echo "k8s-node-$node-routing.sh"
              echo "sudo ip route add $pod_cidr via $node_internal_ip" >> .tmp/k8s-node-$node-routing.sh
          fi        
      done
      echo "Copying Routing File to k8s-node-$node ==================="
      copyFile 'wrk' '.tmp/k8s-node-'$node'-routing.sh' '' 'k8s-node-'$node
  done
#================================================================
else
  echo "No routing configured, it will be configured during CNI configurations"
fi


  