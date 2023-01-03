#!/bin/bash
echo $k8s_provider
if [ "$k8s_provider" = "libvirt" ]
then
  echo "Provider libvirt"
  uuid=$(uuidgen)
  mac=$(echo 00:60:2f$(od -txC -An -N3 /dev/random|tr \  :))
  #lip=$(echo $ip_start | cut -d'.' -f4)
  ip_add_sub=$(echo $node_ip_start | awk -F. '{NF-=1}1' OFS=.)
  ip_add_add=$ip_add_sub'.1'
cat <<EOF | sudo tee .tmp/vagrant-libvirt-node.xml
<network>
  <name>vagrant-libvirt-node</name>
  <uuid>$uuid</uuid>
  <forward mode='nat'>
    <nat>
      <port start='1024' end='65535'/>
    </nat>
  </forward>
  <bridge name='virbr1' stp='on' delay='0'/>
  <mac address='$mac'/>
  <domain name='$k8s_domain' localOnly='yes'/>
  <ip address='$ip_add_add' netmask='255.255.255.0'>
    <dhcp>
      <range start='$node_ip_start' end='$node_ip_end'/>
    </dhcp>
  </ip>
</network>
EOF
elif [ "$k8s_provider" = "virtualbox" ]
then
    echo "provider virtualbox"
fi


