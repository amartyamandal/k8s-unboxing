#!/bin/bash
source ./configure/functions/utility.sh
if [[ $k8s_provider == "libvirt" ]]
then
for vm in $(virsh list | grep k8s-node | awk '{print $2}')
do
  node=$(echo "$vm" | tail -c 14)
cat << EOF >> .tmp/$node-routing.sh
#!/bin/bash
EOF
  echo "Creating $node-routing.sh ========================"
  for vm in $(virsh list | grep k8s-node | awk '{print $2}')
  do
    instance=$(echo "$vm" | tail -c 14)
    if [ $instance != $node ]
    then
        echo "IP for the Present-node $instance"
        node_internal_ip="$(getIP 'wrk' $instance)"
        echo $node_internal_ip
        pod_cidr=$(run_rmComm 'wrk' $instance 'cat pod_cidr.txt')
        echo "POD CIDR"
        echo $pod_cidr
        echo "ip route add $pod_cidr via $node_internal_ip"
        echo "$node-routing.sh"
        echo "sudo ip route add $pod_cidr via $node_internal_ip" >> .tmp/$node-routing.sh
    fi        
  done
  echo "Copying Routing File to $node ==================="
  copyFile 'wrk' '.tmp/'$node'-routing.sh' '' $node
  echo "configure manual routing"
  run_rmComm 'wrk' $node 'chmod +x '$node'-routing.sh;./'$node'-routing.sh' 
done
elif [[ $k8s_provider == "virtualbox" ]]
then
for vm in $(VBoxManage list vms | grep k8s-node | awk '{print $1}' | cut -c 2-29)
do
  node=$(echo "$vm" | tail -c 14)
cat << EOF >> .tmp/$node-routing.sh
#!/bin/bash
EOF
  echo "Creating $node-routing.sh ========================"
  for vm in $(VBoxManage list vms | grep k8s-node | awk '{print $1}' | cut -c 2-29)
  do
    instance=$(echo "$vm" | tail -c 14)
    if [ $instance != $node ]
    then
        echo "IP for the Present-node $instance"
        node_internal_ip="$(getIP 'wrk' $instance)"
        echo $node_internal_ip
        pod_cidr=$(run_rmComm 'wrk' $instance 'cat pod_cidr.txt')
        echo "POD CIDR"
        echo $pod_cidr
        echo "ip route add $pod_cidr via $node_internal_ip"
        echo "$node-routing.sh"
        echo "sudo ip route add $pod_cidr via $node_internal_ip" >> .tmp/$node-routing.sh
    fi        
  done
  echo "Copying Routing File to $node ==================="
  copyFile 'wrk' '.tmp/'$node'-routing.sh' '' $node
  echo "configure manual routing"
  run_rmComm 'wrk' $node 'chmod +x '$node'-routing.sh;./'$node'-routing.sh' 
done
fi
#================================================================
