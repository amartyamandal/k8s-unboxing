#!/bin/bash

source ./configure/functions/utility.sh
if [ -z "$1" ]
then
    echo "Operation can not be performed"
    exit 1
fi

certpath=$(pwd)/certs
rm .tmp/k8s-node-*-routing.sh 
rm -rf certs/wrknodes kubeconfig/wrknodes
mkdir -p certs/wrknodes
mkdir -p kubeconfig/wrknodes
LB_IP_ADDRESS="$(getIP 'lb')"


cp templates/configure-worker.sh.template .tmp/configure-worker.sh
sed -i 's/@k8s_cni@/'$k8s_cni'/g' .tmp/configure-worker.sh


run_rmComm 'wrk' 'k8s-node-'$1 'rm -rf ./*'


##The Kubelet Client Certificates============================
echo "Generating The Kubelet Client Certificates for worker node "k8s-node-${1}

cat > certs/wrknodes/k8s-node-${1}-csr.json <<EOF
{
  "CN": "system:node:k8s-node-${1}",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "CAN",
      "L": "Toronto",
      "O": "system:nodes",
      "OU": "k8s unboxing",
      "ST": "Ontario"
    }
  ]
}
EOF

NODE_IP="$(getIP 'wrk' 'k8s-node-'$1)"
cfssl gencert -ca=$certpath/ca/ca.pem -ca-key=$certpath/ca/ca-key.pem -config=$certpath/ca/ca-config.json -hostname=k8s-node-${1},${NODE_IP} -profile=kubernetes certs/wrknodes/k8s-node-${1}-csr.json | cfssljson -bare certs/wrknodes/k8s-node-${1}

sleep 5

echo "Generate a kubeconfig files for worker node "k8s-node-${1}

run_rmComm 'wrk' 'k8s-node-'$1 'mkdir certs;mkdir kubeconfigs'
echo "Generate a kubeconfig file for "k8s-node-${1}
#--server=https://${KUBERNETES_PUBLIC_ADDRESS}:6443 \
kubectl config set-cluster k8s_unboxing \
  --certificate-authority=certs/ca/ca.pem \
  --embed-certs=true \
  --server=https://${LB_IP_ADDRESS}:6443 \
  --kubeconfig=kubeconfig/wrknodes/k8s-node-${1}.kubeconfig

kubectl config set-credentials system:node:k8s-node-${1} \
  --client-certificate=certs/wrknodes/k8s-node-${1}.pem \
  --client-key=certs/wrknodes/k8s-node-${1}-key.pem \
  --embed-certs=true \
  --kubeconfig=kubeconfig/wrknodes/k8s-node-${1}.kubeconfig

kubectl config set-context default \
  --cluster=k8s_unboxing \
  --user=system:node:k8s-node-${1} \
  --kubeconfig=kubeconfig/wrknodes/k8s-node-${1}.kubeconfig

kubectl config use-context default --kubeconfig=kubeconfig/wrknodes/k8s-node-${1}.kubeconfig

echo "Copying kubelet client certificates& ca to worker node "k8s-node-${1}

for key in certs/wrknodes/k8s-node-${1}-key.pem certs/wrknodes/k8s-node-${1}.pem certs/ca/ca.pem; do 
  cert_name=$(echo ${key} | cut -d"/" -f3)
  echo $cert_name
  copyFile 'wrk' $key 'certs/'$cert_name 'k8s-node-'$1 
  
done

echo "Distribute the Kubernetes Configuration Files to worker node "k8s-node-${1}


for kubeconfig in kubeconfig/wrknodes/k8s-node-${1}.kubeconfig kubeconfig/prxy/kube-proxy.kubeconfig; do
  config_name=$(echo ${kubeconfig} | cut -d"/" -f3)
  copyFile 'wrk' $kubeconfig 'kubeconfigs/'$config_name 'k8s-node-'$1
done

for kube_binary in kubectl kube-proxy kubelet; do 
  copyFile 'wrk' '.tmp/k8s_'$k8s_V'/'$kube_binary $kube_binary 'k8s-node-'$1
done 


copyFile 'wrk' '.tmp/crictl_'$k8s_CRI_CTL_V'/crictl' '' 'k8s-node-'$1
k8s_oci_runtime=""
if [ -z "${k8s_runtime// }" ]
then
    echo "No runtime specified"
else
    if [ -z "${k8s_runtime_v// }" ]
    then
        echo "runtime version not supplied"
    else
        if [[ "$k8s_runtime" == "crun" ]]
        then
            k8s_oci_runtime=crun
            sed -i 's/@k8s_oci_runtime@/crun/g' .tmp/configure-worker.sh
            echo "copying crun as runc....."
            copyFile 'wrk' '.tmp/crun_'$k8s_runtime_v'/crun' 'runc' 'k8s-node-'$1
        elif [[ "$k8s_runtime" == "runc" ]]
        then
            k8s_oci_runtime=runc
            echo "copying runc....."
            copyFile 'wrk' '.tmp/runc_'$k8s_runtime_v'/runc' '' 'k8s-node-'$1
        elif [[ "$k8s_runtime" == "kata" ]]
        then
            k8s_oci_runtime=kata
            sed -i 's/@k8s_oci_runtime@/kata/g' .tmp/configure-worker.sh
            echo "kata will be build & configured during node configuration....."
        else
            echo "runtime not implmented"
        fi
    fi
fi
sed -i 's/@k8s_oci_runtime@/'$k8s_oci_runtime'/g' .tmp/configure-worker.sh
copyFile 'wrk' '.tmp/contd_'$k8s_CONTD_V 'containerd' 'k8s-node-'$1
copyFile 'wrk' '.tmp/cni_'$k8s_CNI_PLUGIN_V 'cni_plugin' 'k8s-node-'$1

echo "Copy configure-worker.sh"
copyFile 'wrk' '.tmp/configure-worker.sh' '' 'k8s-node-'$1 





  