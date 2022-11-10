#!/bin/bash
source ./configure/functions/utility.sh

#Certificate Authority====================================================
echo "Generating CA configuration file, certificate, and private key..."

rm -rf certs/ca
mkdir -p certs/ca
cat > certs/ca/ca-config.json <<EOF
{
  "signing": {
    "default": {
      "expiry": "8760h"
    },
    "profiles": {
      "kubernetes": {
        "usages": ["signing", "key encipherment", "server auth", "client auth"],
        "expiry": "8760h"
      }
    }
  }
}
EOF

cat > certs/ca/ca-csr.json <<EOF
{
  "CN": "Kubernetes",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "CAN",
      "L": "Toronto",
      "O": "Kubernetes",
      "OU": "CA",
      "ST": "Ontario"
    }
  ]
}
EOF

cfssl gencert -initca certs/ca/ca-csr.json | cfssljson -bare certs/ca/ca


#Client and Server Certificates======================================
##Generate The Admin Client Certificate================
echo "Generating Admin Client Certificate..."

rm -rf certs/admin
mkdir -p certs/admin
certpath=$(pwd)/certs/
cat > certs/admin/admin-csr.json <<EOF
{
  "CN": "admin",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "CAN",
      "L": "Toronto",
      "O": "system:masters",
      "OU": "k8s unboxing",
      "ST": "Ontario"
    }
  ]
}
EOF

cfssl gencert \
  -ca=$certpath/ca/ca.pem \
  -ca-key=$certpath/ca/ca-key.pem \
  -config=$certpath/ca/ca-config.json \
  -profile=kubernetes \
  certs/admin/admin-csr.json | cfssljson -bare certs/admin/admin


echo "Generating Controller Manager Client Certificates..."

rm -rf certs/kubecntrl
mkdir -p certs/kubecntrl

cat > certs/kubecntrl/kube-controller-manager-csr.json <<EOF
{
  "CN": "system:kube-controller-manager",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "CAN",
      "L": "Toronto",
      "O": "system:kube-controller-manager",
      "OU": "k8s unboxing",
      "ST": "Ontario"
    }
  ]
}
EOF

cfssl gencert \
  -ca=$certpath/ca/ca.pem \
  -ca-key=$certpath/ca/ca-key.pem \
  -config=$certpath/ca/ca-config.json \
  -profile=kubernetes \
  certs/kubecntrl/kube-controller-manager-csr.json | cfssljson -bare certs/kubecntrl/kube-controller-manager

##Generate the kube-proxy client certificate and private key===================
echo "Generating the kube-proxy client certificate and private key..."

rm -rf certs/kubprxy
mkdir -p certs/kubprxy


cat > certs/kubprxy/kube-proxy-csr.json <<EOF
{
  "CN": "system:kube-proxy",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "CAN",
      "L": "Toronto",
      "O": "system:node-proxier",
      "OU": "k8s unboxing",
      "ST": "Ontario"
    }
  ]
}
EOF

cfssl gencert \
  -ca=$certpath/ca/ca.pem \
  -ca-key=$certpath/ca/ca-key.pem \
  -config=$certpath/ca/ca-config.json \
  -profile=kubernetes \
  certs/kubprxy/kube-proxy-csr.json | cfssljson -bare certs/kubprxy/kube-proxy

##The Scheduler Client Certificate===================
echo "Generate the kube-scheduler client certificate and private key..."

rm -rf certs/schedulerclient
mkdir -p certs/schedulerclient

cat > certs/schedulerclient/kube-scheduler-csr.json <<EOF
{
  "CN": "system:kube-scheduler",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "CAN",
      "L": "Toronto",
      "O": "system:kube-scheduler",
      "OU": "k8s unboxing",
      "ST": "Ontario"
    }
  ]
}
EOF

cfssl gencert \
  -ca=$certpath/ca/ca.pem \
  -ca-key=$certpath/ca/ca-key.pem \
  -config=$certpath/ca/ca-config.json \
  -profile=kubernetes \
  certs/schedulerclient/kube-scheduler-csr.json | cfssljson -bare certs/schedulerclient/kube-scheduler

##The Service Account Key Pair
echo "Generating the service-account certificate and private key..."

rm -rf certs/svca
mkdir -p certs/svca
cat > certs/svca/service-account-csr.json <<EOF
{
  "CN": "service-accounts",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "CAN",
      "L": "Toronto",
      "O": "Kubernetes",
      "OU": "k8s unboxing",
      "ST": "Ontario"
    }
  ]
}
EOF
echo $certpath
cfssl gencert \
  -ca=$certpath/ca/ca.pem \
  -ca-key=$certpath/ca/ca-key.pem \
  -config=$certpath/ca/ca-config.json \
  -profile=kubernetes \
  certs/svca/service-account-csr.json | cfssljson -bare certs/svca/service-account




##The Kubernetes API Server Certificate
echo "Generating the Kubernetes API Server certificates (LB IP fronting master nodes)..."

rm -rf certs/apiserver
mkdir -p certs/apiserver

KUBERNETES_PUBLIC_ADDRESS="$(getIP 'lb')"

KUBERNETES_HOSTNAMES=kubernetes,kubernetes.default,kubernetes.default.svc,kubernetes.default.svc.cluster,kubernetes.svc.cluster.local

CPND_IPS=""

for (( instance = 1; instance <= $k8s_ncpnd; ++instance )); do
  string=k8s-master-${instance}
  final=${string//[-]/_} 
  CPND_IPS+=","$(getIP 'cp' 'k8s-master-'${instance})
done
echo $CPND_IPS

IP_k8s_lb="$(getIP 'lb')"

cat > certs/apiserver/kubernetes-csr.json <<EOF
{
  "CN": "kubernetes",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "CAN",
      "L": "Toronto",
      "O": "Kubernetes",
      "OU": "k8s unboxing",
      "ST": "Ontario"
    }
  ]
}
EOF
##removing ${KUBERNETES_PUBLIC_ADDRESS} for the time being
host_name=k8s-lb,10.32.0.1,${IP_k8s_lb},127.0.0.1,${KUBERNETES_HOSTNAMES}$CPND_IPS
echo $host_name
cfssl gencert \
  -ca=$certpath/ca/ca.pem \
  -ca-key=$certpath/ca/ca-key.pem \
  -config=$certpath/ca/ca-config.json \
  -hostname=$host_name \
  -profile=kubernetes \
  certs/apiserver/kubernetes-csr.json | cfssljson -bare certs/apiserver/kubernetes

