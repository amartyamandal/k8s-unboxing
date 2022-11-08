#!/bin/bash
source ./configure/functions/utility.sh

cp templates/haproxy.cfg.template .tmp/haproxy.cfg
cp templates/configure-haproxy.sh.template .tmp/configure-haproxy.sh
MS_NDS=""
APPS=""
for (( instance = 1; instance <= $k8s_ncpnd; ++instance )); do
    INTERNAL_IP="$(getIP 'cp' 'k8s-master-'$instance)"
    echo $INTERNAL_IP
    MS_NDS+="server k8s-master-$instance.$k8s_domain $INTERNAL_IP:6443 check"
    APPS+="server k8s-master-$instance.$k8s_domain $INTERNAL_IP:8000\n"
done
sed -i "s/@MS_NDS@/$MS_NDS/g" .tmp/haproxy.cfg
sed -i "s/@APPS@/$APPS/g" .tmp/haproxy.cfg
instance=k8s-lb
INTERNAL_LB_IP="$(getIP 'lb')"
echo $INTERNAL_LB_IP
sed -i 's/'k8s-lb'-ip/'$INTERNAL_LB_IP'/g' .tmp/haproxy.cfg

copyFile 'lb' '.tmp/haproxy.cfg' '' 'k8s-lb'
copyFile 'lb' '.tmp/configure-haproxy.sh' '' 'k8s-lb'
run_rmComm 'lb' 'k8s-lb' 'chmod +x configure-haproxy.sh;./configure-haproxy.sh'


