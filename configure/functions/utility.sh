#!/bin/bash
#####################################
function vgVars() {
    local vg_Var_string=""
    if [ -z "$1" ]
    then
        vg_Var_string="SSHKEY=$node_private_key_name PROVIDER=$k8s_provider IMAGE_NAME=$node_os "
    else
        vg_Var_string="NDCOUNT=$1 SSHKEY=$node_private_key_name PROVIDER=$k8s_provider IMAGE_NAME=$node_os "
    fi
    echo $vg_Var_string
}
#####################################
function vg() {
    local vg_string=""
    
    if [[ "$1" == "cp" ]]
    then
        vgVar=$(vgVars $k8s_ncpnd)
        vg_string="VAGRANT_VAGRANTFILE=Vagrantfile.k8s_master VAGRANT_DOTFILE_PATH=.vagrant_k8s_master "$vgVar" vagrant"
    elif [[ "$1" == "wrk" ]]
    then
        vgVar=$(vgVars $k8s_nwrknd)
        vg_string="VAGRANT_VAGRANTFILE=Vagrantfile.k8s_node VAGRANT_DOTFILE_PATH=.vagrant_k8s_node "$vgVar" vagrant"
    elif [[ "$1" == "lb" ]]
    then
        vgVar=$(vgVars)
        vg_string="VAGRANT_VAGRANTFILE=Vagrantfile.k8s_lb VAGRANT_DOTFILE_PATH=.vagrant_k8s_lb "$vgVar" vagrant "
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
####################################################
function validate_yaml_input {
    if [ -z "${k8s_provider// }" ]
    then
        echo "k8s version not supplied"
        exit 1
    fi
    if [ -z "${k8s_domain// }" ]
    then
        echo "domain value not supplied"
        exit 1
    fi
    if [ -z "${k8s_ip_start// }" ]
    then
        echo "ip_start value not supplied"
        exit 1
    fi
    if [ -z "${k8s_ip_end// }" ]
    then
        echo "ip_end value not supplied"
        exit 1
    fi
    if [ -z "${k8s_ncpnd// }" ]
    then
        echo "control plane number of nodes not supplied"
        exit 1
    fi
    if [ -z "${k8s_nwrknd// }" ]
    then
        echo "Number of worker nodes not supplied"
        exit 1
    fi
    if [ -z "${k8s_cni// }" ]
    then
        echo "CNI option not supplied"
        exit 1
    fi
    if [ -z "${k8s_V// }" ]
    then
        echo "k8s version not supplied"
        exit 1
    fi
    if [ -z "${k8s_CRI_CTL_V// }" ]
    then
        echo "CRI tool version not supplied"
        exit 1
    fi
    if [ -z "${k8s_RUNC_V// }" ]
    then
        if [ -z "${k8s_CRUN_V// }" ]
        then
            echo "runc version not supplied"
            exit 1
        fi
    fi
    if [ -z "${k8s_CONTD_V// }" ]
    then
        echo "containerd version not supplied"
        exit 1
    fi
    if [ -z "${k8s_CNI_PLUGIN_V// }" ]
    then
        echo "cni plugin version not supplied"
        exit 1
    fi
    if [ -z "${k8s_build_directory// }" ]
    then
        echo "k8 build directory path not supplied"
        exit 1
    fi
    if [ -z "${k8s_CRUN_V// }" ]
    then
        if [ -z "${k8s_RUNC_V// }" ]
        then
            echo "crun version not supplied"
            exit 1
        fi
    fi
    if [ -z "${node_private_key_name// }" ]
    then
        echo "node_private_key_name value not supplied"
        exit 1
    fi
    if [ -z "${node_os// }" ]
    then
        echo "node_os value not supplied"
        exit 1
    fi
    if [ ${#k8s_CRUN_V} -gt 0 ] && [ ${#k8s_RUNC_V} -gt 0 ]
    then
        echo "Only keep one runc option either runc or crun, remove one"
        exit 1
    fi
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
    echo $vg $2
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