#!/bin/bash
#####################################
function vg() {
    local vg_string=""
    if [[ "$1" == "cp" ]]
    then
        vg_string="VAGRANT_VAGRANTFILE=Vagrantfile.k8s_master VAGRANT_DOTFILE_PATH=.vagrant_k8s_master N_CPND=$k8s_ncpnd SSHKEY=$node_private_key_name PROVIDER=$k8s_provider vagrant"
    elif [[ "$1" == "wrk" ]]
    then
        vg_string="VAGRANT_VAGRANTFILE=Vagrantfile.k8s_node VAGRANT_DOTFILE_PATH=.vagrant_k8s_node N_WRKND=$k8s_nwrknd PROVIDER=$k8s_provider SSHKEY=$node_private_key_name vagrant"
    elif [[ "$1" == "lb" ]]
    then
        vg_string="VAGRANT_VAGRANTFILE=Vagrantfile.k8s_lb VAGRANT_DOTFILE_PATH=.vagrant_k8s_lb PROVIDER=$k8s_provider SSHKEY=$node_private_key_name vagrant"
    else
        echo "No node selected"
    fi
    echo $vg_string
}
#####################################
#$1=type
#$2=source path
#$3=destination path
#$4=instance
#$5=count
function copyFile() {
    vg=$(vg $1)
    eval "$(echo $vg scp $2 $4:~/$3)"
}
############################################
function getIface() {
    local dflt_net_iface=eth0
    if [ "$k8s_provider" = "virtualbox" ]
    then
        dflt_net_iface=eth1
    fi
    echo "$dflt_net_iface"
}
###############################################

function getIP() {
    default_network_interface=$(getIface)
    vg=$(vg $1)
    local NODE_IP=$(eval "$(echo $vg ssh $2 -- ip -4 addr show $default_network_interface) | grep -oP '(?<=inet\s)\d+(\.\d+){3}'")    
    echo "$NODE_IP"
}
####################################################
function parse_yaml {
   #printf "#!/bin/bash\n\n"
   #printf "function declare_k8s_env {\n"
   local prefix=$2
   local s='[[:space:]]*' w='[a-zA-Z0-9_]*' fs=$(echo @|tr @ '\034')
   sed -ne "s|^\($s\):|\1|" \
        -e "s|^\($s\)\($w\)$s:$s[\"']\(.*\)[\"']$s\$|\1$fs\2$fs\3|p" \
        -e "s|^\($s\)\($w\)$s:$s\(.*\)$s\$|\1$fs\2$fs\3|p"  $1 |
   awk -F$fs '{
      indent = length($1)/2;
      vname[indent] = $2;
      
      for (i in vname) {if (i > indent) {delete vname[i]}}
      if (length($3) > 0) {
         vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
         printf("export %s%s%s=\"%s\"\n", "'$prefix'",vn, $2, $3);
      }
   }'
   #printf "}"
}
######################################################
#$1=type
#$2=instance
#$3=command
#$4=count
function run_rmComm() {
    vg=$(vg $1)
    local  output=$(eval "$(echo $vg ssh $2 -c "'${3}'")")
    echo "$output" | tr '\r' ' '
}
###########################################
function ndops() {
    vg=$(vg $1)
    eval "$(echo $vg $2)"
}
###########################################
function getndCount() {

    local ndcount=0 
    if [ "$2" = "virtualbox" ]
    then
        if [[ "$1" == "cp" ]]
        then
            ndcount=$(VBoxManage list vms | grep k8s-master -c)
        elif [[ "$1" == "wrk" ]]
        then
            ndcount=$(VBoxManage list vms | grep k8s-node -c)
        elif [[ "$1" == "lb" ]]
        then
            ndcount=$(VBoxManage list vms | grep k8s-lb -c)
        fi
    elif [ "$2" = "libvirt" ]
    then
        if [[ "$1" == "cp" ]]
        then
            ndcount=$(virsh list --all | grep k8s-master -c)
        elif [[ "$1" == "wrk" ]]
        then
            ndcount=$(virsh list --all | grep k8s-node -c)
        elif [[ "$1" == "lb" ]]
        then
            ndcount=$(virsh list --all | grep k8s-lb -c)
        fi
    fi
   
    echo "$ndcount"
}

function delNs() {
    
    NAMESPACE=$1
    ns_status=$(kubectl get ns $NAMESPACE -o jsonpath='{.status.phase}')
    if [[ "$ns_status" == "Terminating" ]]
    then
        kubectl proxy &
        kubectl get namespace $NAMESPACE -o json |jq '.spec = {"finalizers":[]}' >temp.json
        curl -k -H "Content-Type: application/json" -X PUT --data-binary @temp.json 127.0.0.1:8001/api/v1/namespaces/$NAMESPACE/finalize
    fi
    
}

function validateInput() {

    commands=(all cp wrk del "del wrk" make build); 
    d=$'\1'   # validation delimiter - value is \x01
    valid="${commands[@]/%/$d}"
    valid="$d${valid//$d /$d}"

    if [[ $valid == *$d$INPUT$d* ]] ;then 
        echo "$INPUT: ok"
    else 
        echo "$INPUT: not recognized. Valid commands are:"
        echo "${commands[@]/%/,}"
        exit 1
    fi

}