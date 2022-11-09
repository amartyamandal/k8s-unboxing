# k8s-unboxing
Generally I use kvm in my home lab, poor man's hypervisor. You need some sort of automation so that you can quickly change, build, destroy & redo a cluster whenever you want in the cheapest way possible.

Purpose of this very first blog of this series is to introduce the following collection of scripts which let you create a k8s cluster with an api load balancer with both libvirt (kvm) and virtualbox.

You can find the source here [https://github.com/amartyamandal/k8s-unboxing](https://github.com/amartyamandal/k8s-unboxing).

Once download first thing you would like to do is to update k8s-config.yaml


Github repo documentation still a work in progress and grow along with this series and will bring more clarity, it's only bash scripts (other than one exception of ansible, just to keep an entry point for future enhancement), using only bash is intentional, code is very much straight forward easy to understand and change and that is the primary objectives.

following table would be helpful-

| ./setup.sh make | Download source code for Kubernetes, Cri-tools, runc, containerd & cni plugins. |
| --- | --- |
| ./setup.sh build | Build Kubernetes, Cri-tools, runc, containerd & cni plugins and copy to the main project tmp folder, so that any changes made to any of this source is readily available for testing.
**NOTE:** etcd is the only binary which is getting downloaded and not getting build locally |
| ./setup.sh all | Create control plane vm's, load balancer and worker nodes based on the k8s-config configuration and install all the binaries |
| ./setup.sh cp | Only creates the control plane |
| ./setup.sh wrk | If control plane exists creates worker nodes and configure the same |
| ./setup.sh del | Destroy entire cluster |
| ./setup.sh del wrk | Only remove the worker nodes, so that you can redeploy the worker nodes with changes you made, keeping the control plane intact |

FYI- "build" for the first time will take some time mostly to build k8s binaries, do check "build-k8s.sh" under scripts directory for the build command and you are free to make changes according to your environment
 ![](RackMultipart20221109-1-no568q_html_e63ac52501a6cd39.png)

Building containerd may have some complain around libseccomp and you may download compile build the same with following commands

Sometimes changing virtualization providers from virtualbox to libvirt causes some trouble simply restart libvirtd and remove stale images.

Few things to remember before using this repo.

1. Its inspired by "kubernetes the hard way"- it's just an enhancement to use cheaper infra provisioning platform or tools like virtualbox or kvm
2. This is not any tool or has no intention to become one, in fact its opposites, its whole purpose is to unwrap installation and configuration of a cluster in its full glory
3. This is no way optimized for time (it takes to build a cluster) or efficiency (I purposefully avoided using ansible or any sorts of cm), it's expressive and fragile.
4. I have ansible provisioner with vagrant, but use has been kept very limited, its mostly collection of few bash script and that is intentional
5. Pre-requisites
  1. I use ubuntu for my development machine, it should also work in a debian distribution
  2. [Go](https://www.fosslinux.com/68795/install-go-on-ubuntu.htm)
  3. [Kvm](https://www.fosslinux.com/68795/install-go-on-ubuntu.htm) or [virtualbox](https://linuxhint.com/install-virtualbox-linux/)- I should warn kvm is much much faster, reason is obvious kvm is type 1 hypervisor
  4. [Vagrant](https://linuxhint.com/install-vagrant-ubuntu/), vagrant virtualbox provider and [libvirt providers](https://computingforgeeks.com/using-vagrant-with-libvirt-on-linux/)
  5. Virsh and Vboxmanage command lines, which should be installed once you configured libvirt and virtualbox
  6. Cilium command line if you are using cilium, but my suggestions would be to start with default
  7. If anything else, rest assured deployment will certainly break and let you know what is wrong :-)
  8. It will ask for "sudo", you are welcome to check the code before you go with it, nothing harmful though

