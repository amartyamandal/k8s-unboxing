#!/bin/bash
project_path=$(eval pwd)

DIR_KUBE=$project_path/.tmp/k8s_$k8s_V
DIR_CRI_CTL=$project_path/.tmp/crictl_$k8s_CRI_CTL_V

DIR_CONTD=$project_path/.tmp/contd_$k8s_CONTD_V
DIR_CNI_PLUGIN=$project_path/.tmp/cni_$k8s_CNI_PLUGIN_V


if [ -d "$DIR_KUBE" ];
then
    echo "k8s binaries exists for version "$k8s_V
else
    echo "build & copy k8s binaries for version "$k8s_V
    
    k8s_path=$k8s_build_directory/kubernetes 
    k8s_binary_path=$k8s_path/_output/dockerized/bin/linux/amd64/
    

    cd $k8s_path

    git checkout release-$k8s_V
    sudo build/make-clean.sh

    sudo build/run.sh make kube-apiserver KUBE_BUILD_PLATFORMS=linux/amd64
    sudo build/run.sh make kube-controller-manager KUBE_BUILD_PLATFORMS=linux/amd64
    sudo build/run.sh make kube-scheduler KUBE_BUILD_PLATFORMS=linux/amd64
    sudo build/run.sh make kubectl KUBE_BUILD_PLATFORMS=linux/amd64
    sudo build/run.sh make kube-proxy KUBE_BUILD_PLATFORMS=linux/amd64
    sudo build/run.sh make kubelet KUBE_BUILD_PLATFORMS=linux/amd64

    sudo mkdir $DIR_KUBE
    #cd $k8s_binary_path
    
    sudo cp $k8s_binary_path/kube-apiserver $DIR_KUBE/kube-apiserver
    sudo cp $k8s_binary_path/kube-controller-manager $DIR_KUBE/kube-controller-manager
    sudo cp $k8s_binary_path/kube-scheduler $DIR_KUBE/kube-scheduler
    sudo cp $k8s_binary_path/kubectl $DIR_KUBE/kubectl
    sudo cp $k8s_binary_path/kube-proxy $DIR_KUBE/kube-proxy
    sudo cp $k8s_binary_path/kubelet $DIR_KUBE/kubelet
fi

if [ -d "$DIR_CRI_CTL" ];
then
    echo "crictl binaries exists for version "$k8s_CRI_CTL_V
else
    echo "build & copy crictl binaries for version "$k8s_CRI_CTL_V
    
    crictl_path=$k8s_build_directory/cri-tools 
    crictl_binary_path=$crictl_path/build/bin/
    

    cd $crictl_path

    git checkout release-$k8s_CRI_CTL_V
    sudo make

    sudo mkdir $DIR_CRI_CTL
    #cd $crictl_binary_path
    
    sudo cp $crictl_binary_path/crictl $DIR_CRI_CTL/crictl
   
fi

if [ -d "$DIR_CONTD" ];
then
    echo "containerd binaries exists for version "$k8s_CONTD_V
else
    echo "build & copy containerd binaries for version "$k8s_CONTD_V
    
    contd_path=$k8s_build_directory/containerd 
    contd_binary_path=$contd_path/bin
    

    cd $contd_path

    git checkout release/$k8s_CONTD_V
    sudo make

    sudo mkdir $DIR_CONTD
    #cd $contd_binary_path
    
    sudo cp -r $contd_binary_path/* $DIR_CONTD/
   
fi

if [ -d "$DIR_CNI_PLUGIN" ];
then
    echo "CNI Plugin binaries exists for version "$k8s_CNI_PLUGIN_V
else
    echo "build & copy CNI Plugin binaries for version "$k8s_CNI_PLUGIN_V
    
    cni_path=$k8s_build_directory/plugins 
    cni_binary_path=$cni_path/bin
    

    cd $cni_path

    git checkout release-$k8s_CNI_PLUGIN_V
    sudo ./build_linux.sh
    sudo mkdir $DIR_CNI_PLUGIN
    #cd $contd_binary_path
    
    sudo cp -r $cni_binary_path/* $DIR_CNI_PLUGIN/
   
fi

if [ -z "${node_runtime// }" ]
then
    echo "No runtime specified"
else
    if [ -z "${node_runtime_v// }" ]
    then
        echo "runtime version not supplied"
    else
        if [[ "$node_runtime" == "crun" ]]
        then
            DIR_CRUN=$project_path/.tmp/crun_$node_runtime_v
            if [ -d "$DIR_CRUN" ];
            then
                echo "crun binaries exists for version "$node_runtime_v
            else
                echo "build & copy crun binaries for main "
            
                
                crun_path=$k8s_build_directory/crun
                crun_binary_path=$crun_path
                
                #echo $crun_binary_path

                cd $crun_path
                

                git checkout $node_runtime_v
                sudo ./autogen.sh
                sudo ./configure  #--enable-shared
                sudo make

                sudo mkdir $DIR_CRUN
                
                
                sudo cp $crun_binary_path/crun $DIR_CRUN/crun
            fi
        elif [[ "$node_runtime" == "runc" ]]
        then
            DIR_RUNC=$project_path/.tmp/runc_$node_runtime_v
            if [ -d "$DIR_RUNC" ];
            then
                echo "runc binaries exists for version "$node_runtime_v
            else
                echo "build & copy runc binaries for version "$node_runtime_v
                
                runc_path=$k8s_build_directory/runc 
                runc_binary_path=$runc_path
                

                cd $runc_path

                git checkout release-$node_runtime_v
                sudo make

                sudo mkdir $DIR_RUNC
                #cd $runc_binary_path
                
                sudo cp $runc_binary_path/runc $DIR_RUNC/runc
            
            fi
        elif [[ "$node_runtime" == "kata" ]]
        then
            echo "runtime will be built in the worker node itself"
        elif [[ "$node_runtime" == "gvisor" ]]
        then
            echo "runtime will be built in the worker node itself"
        else
            echo "runtime not implmented"
        fi
    fi
fi

