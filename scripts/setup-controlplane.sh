#!/bin/bash 
source ./configure/functions/utility.sh
###########################################################################
if [ "$k8s_provider" = "libvirt" ]
then
    echo "Defining the vagrant-virtualbox network..."

    ###required for libvirt#################
    #sudo virsh net-create --file .tmp/vagrant-libvirt.xml
    sudo virsh net-define --file .tmp/vagrant-libvirt.xml
    sudo virsh net-start vagrant-libvirt
    sudo virsh net-autostart vagrant-libvirt
    # AGRANT_LOG=debug vagrant up
    ########################################
fi
echo "Creating Master Nodes..." ###########################################
#ndops cp 'global-status --prune'
ndops cp up

echo "Creating load balancer vm..." ########################################
#ndops lb 'global-status --prune'
ndops lb up

echo "Configuring controlplane-dns-entry..." ###############################
./configure/controlplane-dns-entry.sh

echo "Configuring hosts-controlplane-script..." ###############################
./configure/configure-hosts-controlplane-script.sh

echo "Creating and deploying certificates for control plane..." ############
./scripts/gen_certs.sh

echo "Creating and deploying kubeconfigs for control plane..." #############
./scripts/gen_kube_config.sh

echo "Configuring haproxy config with backend master nodes..." #############
./configure/configure-haproxy-script.sh

echo "Configure etcd install script..." ####################################
./configure/configure_etcd_script.sh 
./configure/apply_etcd_script.sh 

echo "Configure k8s controlplane install script..."#########################
./configure/configure-controlplane-script.sh
./configure/apply-controlplane-script.sh

############################################################################
sleep 10

