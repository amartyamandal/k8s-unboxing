#!/bin/bash

function declare_k8s_env {
	export k8s_provider="libvirt"
	export k8s_domain="vindpro.de"
	export k8s_ip_start="192.168.121.128"
	export k8s_ip_end="192.168.121.254"
	export k8s_ncpnd="1"
	export k8s_nwrknd="2"
	export k8s_cni="default"
	export k8s_K8S_V="1.22"
	export k8s_CRI_CTL_V=".25"
	export k8s_RUNC_V="1.1"
	export k8s_CONTD_V="1.6.8"
}