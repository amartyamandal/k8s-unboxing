#!/bin/bash
source ./configure/functions/utility.sh

LB_IP_ADDRESS="$(getIP 'lb')"

echo "Generate a kubeconfig file for the kube-proxy service..."

rm -rf kubeconfig/prxy
mkdir -p kubeconfig/prxy
#--server=https://${KUBERNETES_PUBLIC_ADDRESS}:6443 \
kubectl config set-cluster k8s_unboxing \
    --certificate-authority=certs/ca/ca.pem \
    --embed-certs=true \
    --server=https://${LB_IP_ADDRESS}:6443 \
    --kubeconfig=kubeconfig/prxy/kube-proxy.kubeconfig

kubectl config set-credentials system:kube-proxy \
  --client-certificate=certs/kubprxy/kube-proxy.pem \
  --client-key=certs/kubprxy/kube-proxy-key.pem \
  --embed-certs=true \
  --kubeconfig=kubeconfig/prxy/kube-proxy.kubeconfig

kubectl config set-context default \
  --cluster=k8s_unboxing \
  --user=system:kube-proxy \
  --kubeconfig=kubeconfig/prxy/kube-proxy.kubeconfig

kubectl config use-context default --kubeconfig=kubeconfig/prxy/kube-proxy.kubeconfig

echo "Generate a kubeconfig file for the kube-controller-manager service..."

rm -rf kubeconfig/kubecntrl
mkdir -p kubeconfig/kubecntrl
kubectl config set-cluster k8s_unboxing \
    --certificate-authority=certs/ca/ca.pem \
    --embed-certs=true \
    --server=https://127.0.0.1:6443 \
    --kubeconfig=kubeconfig/kubecntrl/kube-controller-manager.kubeconfig

kubectl config set-credentials system:kube-controller-manager \
  --client-certificate=certs/kubecntrl/kube-controller-manager.pem \
  --client-key=certs/kubecntrl/kube-controller-manager-key.pem \
  --embed-certs=true \
  --kubeconfig=kubeconfig/kubecntrl/kube-controller-manager.kubeconfig

kubectl config set-context default \
  --cluster=k8s_unboxing \
  --user=system:kube-controller-manager \
  --kubeconfig=kubeconfig/kubecntrl/kube-controller-manager.kubeconfig

kubectl config use-context default --kubeconfig=kubeconfig/kubecntrl/kube-controller-manager.kubeconfig

echo "Generate a kubeconfig file for the kube-scheduler service..."

rm -rf kubeconfig/schedulerclient
mkdir -p kubeconfig/schedulerclient
kubectl config set-cluster k8s_unboxing \
    --certificate-authority=certs/ca/ca.pem \
    --embed-certs=true \
    --server=https://127.0.0.1:6443 \
    --kubeconfig=kubeconfig/schedulerclient/kube-scheduler.kubeconfig

kubectl config set-credentials system:kube-scheduler \
  --client-certificate=certs/schedulerclient/kube-scheduler.pem \
  --client-key=certs/schedulerclient/kube-scheduler-key.pem \
  --embed-certs=true \
  --kubeconfig=kubeconfig/schedulerclient/kube-scheduler.kubeconfig

kubectl config set-context default \
  --cluster=k8s_unboxing \
  --user=system:kube-scheduler \
  --kubeconfig=kubeconfig/schedulerclient/kube-scheduler.kubeconfig

kubectl config use-context default --kubeconfig=kubeconfig/schedulerclient/kube-scheduler.kubeconfig
echo "Generate a kubeconfig file for the admin user..."

rm -rf kubeconfig/admin
mkdir -p kubeconfig/admin
kubectl config set-cluster k8s_unboxing \
    --certificate-authority=certs/ca/ca.pem \
    --embed-certs=true \
    --server=https://127.0.0.1:6443 \
    --kubeconfig=kubeconfig/admin/admin.kubeconfig

kubectl config set-credentials admin \
  --client-certificate=certs/admin/admin.pem \
  --client-key=certs/admin/admin-key.pem \
  --embed-certs=true \
  --kubeconfig=kubeconfig/admin/admin.kubeconfig

kubectl config set-context default \
  --cluster=k8s_unboxing \
  --user=admin \
  --kubeconfig=kubeconfig/admin/admin.kubeconfig

kubectl config use-context default --kubeconfig=kubeconfig/admin/admin.kubeconfig

ENCRYPTION_KEY=$(head -c 32 /dev/urandom | base64)
cat > kubeconfig/encryption-config.yaml <<EOF
kind: EncryptionConfig
apiVersion: v1
resources:
  - resources:
      - secrets
    providers:
      - aescbc:
          keys:
            - name: key1
              secret: ${ENCRYPTION_KEY}
      - identity: {}
EOF

