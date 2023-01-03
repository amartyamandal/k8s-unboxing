#!/bin/bash

sudo virt-clone --original k8s-local-hard_k8s-node-1174 --name newdemo --file .tmp/node_profiles/newdemo.img --file .tmp/node_profiles/newdata.img --check disk_size=off
virsh domblklist k8s-local-hard_k8s-node-1174 --details | awk '{print $4}' | awk 'NR==3'
declare -a vm_array=()
    for vm in $(virsh list | grep k8s-node | awk '{print $2}')
    do
        vm_name=$(echo "$vm")
        vm_array+=("$vm_name")
    done
     # for value in "${vm_array[@]}"
    # do
    #      echo $value
    # done
    #IFS=$'\n'
    #echo "${vm_array[*]}" | sort -nr | head -n1
    
    max=0
    vmToRemove=""
   
    for n in "${vm_array[@]}" ; do
        number=$(echo $n | tail -c 5)
        if (( $number > $max ))
        then 
            max=$number
            vmToRemove=$n
        fi
    done
    echo $vmToRemove
# RAM
#

# echo "RAM"
# echo "---"

# SUM=0

# while read vm
# do
# 	if [ ! -z "$vm" ]; then
# 		USED=$(($(virsh dominfo $vm | grep "Max memory" | cut -f 7 -d " ") / 1024))
#                 printf "%-25s = %'.0f MiB\n" $vm $USED
# 		SUM=$((SUM + USED))
# 	fi
# done < <(virsh list --all --name)

# printf "\nTotal: %'.0f MiB\n\n" $SUM

# #
# # CPUs
# #

# echo "CPU(s)"
# echo "------"

# SUM=0

# while read vm
# do
# 	if [ ! -z "$vm" ]; then
# 		USED=$(virsh dominfo $vm | grep "CPU(s)" | cut -f 10 -d " ")
# 		printf "%-25s = %'.0f cpu(s)\n" $vm $USED
# 		SUM=$((SUM + USED))
# 	fi
# done < <(virsh list --all --name)

# printf "\nTotal: %'.0f CPU(s)\n" $SUM