# k8s-unboxing
Generally I use kvm in my home lab, poor man's hypervisor. You need some sort of automation so that you can quickly change, build, destroy & redo a cluster whenever you want in the cheapest way possible.

Purpose of this collection of scripts is to let you create a k8s cluster with an api load balancer with both libvirt (kvm) and virtualbox.

Once download first thing you would like to do is to update k8s-config.yaml

<pre><code>
## global definitions
# k8s:
#   provider: 'libvirt'       ## two options 'libvirt' or 'virtualbox'#######################################
#   domain: 'k8s.local'
#   ip_start: 192.168.121.128 ## This is required for libvirt provider to create a subnet ###################
#   ip_end: 192.168.121.254   ## for virtualbox its use the default vboxnet0 ################################
#   ncpnd: 1                  ## number of master nodes, load balancer will balanced the traffic to kubeapi##
#   nwrknd: 2                 ## number of worker nodes #####################################################
#   cni: "default"            ## 3 options 'default'(simple routing & no 3rd party CNI),'calico','cilium' ###
#   V: 1.22                   ## k8s version ################################################################
#   CRI_CTL_V: 1.25           ## CRI version ################################################################
#   runtime: runc | crun | kata | gvisor
#   runtime_v: low level runtime versions runc version = 1.1; crun version = 1.7; kata version = 2.4.2                  
#        gvisor version =  20221128.0 at present snap install version for kata 2.4.2, let's keep it that way!
#        for kata & gvisor runtime version has no effect, because it is always getting the latest source  
#        during provisioning of the nodes, its not ideal, but at this moment, either of this special runtime  
#        not stable, documentation not clear, so its better to do the runtime build and configuration inside 
#        the node, remember its a test bench for kubernetes
#   CONTD_V: 1.6             ## containerd version #########################################################
#   CNI_PLUGIN_V: 1.1        ## cni plugin version #########################################################
#   build_directory: "<path>"## path to the directory where you downloaded & build all k8s related source ## 
# node:                          ## any node attrebutes can be configured here ##########################      
#   private_key_name: "<ssh_key>"## ssh key name to ssh into the nodes,expect key in default ~/.ssh path 
#   os: "generic/ubuntu2204"     ## os ubuntu is the only flavour which has been tested


k8s:
  provider: "libvirt"
  domain: "<domain>"
  ip_start: 192.168.121.128
  ip_end: 192.168.121.254
  ncpnd: 1
  nwrknd: 2
  cni: "default"
  V: 1.25
  CRI_CTL_V: 1.25
  runtime: "kata"
  runtime_v: 2.4.2
  CONTD_V: 1.6
  CNI_PLUGIN_V: 1.1
  build_directory: "<path>"
node:
  private_key_name: "ssh_key"
  os: "generic/ubuntu2204"
</code></pre>
Github repo documentation still a work in progress and grow along with this series and will bring more clarity, it's only bash scripts (other than one exception of ansible, just to keep an entry point for future enhancement), using only bash is intentional, code is very much straight forward easy to understand and change and that is the primary objectives.

following table would be helpful
|command|usage|
|-------|-----|
|<pre><code>./setup.sh make</code></pre>| Download source code for Kubernetes, Cri-tools, runc, containerd & cni plugins. |
|<pre><code>./setup.sh build</code></pre>| Build Kubernetes, Cri-tools, runc, containerd & cni plugins and copy to the main project tmp folder, so that any changes made to any of this source is readily available for testing.|
||**NOTE:** etcd is the only binary which is getting downloaded and not getting build locally|
|<pre><code>./setup.sh all</code></pre>| Create control plane vm's, load balancer and worker nodes based on the k8s-config configuration and install all the binaries |
|<pre><code>./setup.sh cp</code></pre>| Only creates the control plane |
|<pre><code>./setup.sh scale</code></pre>| If control plane exists creates or remove worker nodes and configure the same, scale command compare worker nodes at present vs required based on the number updated in k8s-config.yaml and scale up or scale down accordingly, to remove all the worker nodes just specify "0" for "nwrknd" in config, that will basically scale down to 0 |
||**NOTE:** Change to the cni plugin, will only take effect, if you are provisioning worker nodes for the first time or scaling down to 0 and re-provisioning once again. For this specific release its only been tested with default cni which is just simple routing, other options may provide upredicted results|
|<pre><code>./setup.sh del</code></pre>| Destroy entire cluster |


Following should be the right sequence of commands for the first time users...

<pre><code>./setup.sh make
./setup.sh build
./setup.sh all</code></pre>



FYI- "build" for the first time will take some time mostly to build k8s binaries, do check "build-k8s.sh" under scripts directory for the build command and you are free to make changes according to your environment
 <pre><code>
    sudo build/run.sh make kube-apiserver KUBE_BUILD_PLATFORMS=linux/amd64
    sudo build/run.sh make kube-controller-manager KUBE_BUILD_PLATFORMS=linux/amd64
    sudo build/run.sh make kube-scheduler KUBE_BUILD_PLATFORMS=linux/amd64
    sudo build/run.sh make kubectl KUBE_BUILD_PLATFORMS=linux/amd64
    sudo build/run.sh make kube-proxy KUBE_BUILD_PLATFORMS=linux/amd64
    sudo build/run.sh make kubelet KUBE_BUILD_PLATFORMS=linux/amd64
</code></pre>

Building containerd may have some complain around libseccomp and you may download compile build the same with following commands
<pre><code>git clone https://github.com/seccomp/libseccomp
git checkouot release-2.5
./autogen.sh
./configure
make install
make check
</code></pre>

Sometimes changing virtualization providers from virtualbox to libvirt causes some trouble simply restart libvirtd and remove stale images.

Few things to remember before using this repo.

1. Its inspired by "kubernetes the hard way"- it's just an enhancement to use cheaper infra provisioning platform or tools like virtualbox or kvm
2. This is not any tool or has no intention to become one, in fact its opposites, its whole purpose is to unwrap installation and configuration of a cluster in its full glory
3. This is no way optimized for time (it takes to build a cluster) or efficiency (I purposefully avoided using ansible or any sorts of cm), it's expressive and fragile.
4. I have ansible provisioner with vagrant, but use has been kept very limited, its mostly collection of few bash script and that is intentional
# Pre-requisites
  * I use ubuntu for my development machine, it should also work in a debian distribution
  * [Go](https://www.fosslinux.com/68795/install-go-on-ubuntu.htm)
  * [Kvm](https://www.fosslinux.com/68795/install-go-on-ubuntu.htm) or [virtualbox](https://linuxhint.com/install-virtualbox-linux/)- 
    I should warn kvm is much much faster, reason is obvious kvm is type 1 hypervisor
  * [Vagrant](https://linuxhint.com/install-vagrant-ubuntu/), vagrant virtualbox provider and [libvirt providers](https://computingforgeeks.com/using-vagrant-with-libvirt-on-linux/)
  * Virsh and Vboxmanage command lines, which should be installed once you configured kvm and virtualbox
  * Cilium command line if you are using cilium, but my suggestions would be to start with default
  * If anything else, rest assured deployment will certainly break and let you know what is wrong :-)
  * It will ask for "sudo", you are welcome to check the code before you go with it, nothing harmful though
  * ansible


**NOTE:** do not forget to downgrade or upgrade kubectl version while changing k8s version more than one version up or down

**WARNING!!** it doese update your /etc/hosts, but before that it keeps a backup.You can switch it off though
There are two templates for hosts under folder "templates" one for the guest (hosts.node.template) and otherone for the host.
in case you have customization in your existing host file just replace the hosts.template (which is for host) and just update with following bold placeholders

<pre><code>
127.0.0.1       localhost
</code></pre>
**`@CPHOSTS@`**   
**`k8s-lb-ip k8s-lb.@DOMAIN@`**  
**`@WRKHOSTS@`**
<pre><code>
# The following lines are desirable for IPv6 capable hosts
::1     ip6-localhost ip6-loopback
fe00::0 ip6-localnet
ff00::0 ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
</code></pre>

# Notes on kata
[kata](https://github.com/kata-containers/kata-containers) going through some major changes and documentation is hard to follow.
Ideally kata runtime should be build and separately and copied to specific node, it is only required to check if node is capable of creating a Kata Container.
Ideally these checks should not be part of node provisioning, but for the clarity of understanding, I am building kata runtime from source in the node itself.
This will change later to more standard approach.

# Notes on gvisor
[gvisor](https://github.com/google/gvisor) has a major limitation with ubuntu.
The new systemd 247.2-2 has switched to a new "unified" cgroup hierarchy (i.e. cgroup v2) which is not supported by gVisor.
Ubuntu version 21.10 & above affected.
Workaround is to switching back to cgroup v1 and that's why a node created with gvisor runtime will reboot to reflect the downgrade 
