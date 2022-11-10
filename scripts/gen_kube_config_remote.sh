#!/bin/bash
source ./configure/functions/utility.sh

LB_IP_ADDRESS="$(getIP 'lb')"

echo "Generate a kubeconfig file for remote use..."

kubectl config set-cluster k8s_unboxing \
    --certificate-authority=certs/ca/ca.pem \
    --embed-certs=true \
    --server=https://${LB_IP_ADDRESS}:6443

kubectl config set-credentials admin \
  --client-certificate=certs/admin/admin.pem \
  --client-key=certs/admin/admin-key.pem \

kubectl config set-context k8s_unboxing \
  --cluster=k8s_unboxing \
  --user=admin

kubectl config use-context k8s_unboxing

