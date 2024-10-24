#!/bin/bash
#Docker Download
mkdir -p /datadrive/airgap/images
mkdir -p /datadrive/airgap/rpms
cd /datadrive/airgap/images/

yum install -y yum-utils
yum-config-manager --add-repo https://download.docker.com/linux/rhel/docker-ce.repo
yum download docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

#Kubernetes Download

cat <<EOF | tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.30/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.30/rpm/repodata/repomd.xml.key
EOF

cd /datadrive/airgap/rpms
yum download kubelet kubeadm kubectl conntrack-tools cri-tools iptables-nft kubernetes-cni libnetfilter_cthelper libnetfilter_cttimeout libnetfilter_queue libnftnl socat iproute

# Misc Tools
yum download openscap-scanner scap-security-guide libtool-ltdl libxslt openscap xmlsec1 xmlsec1-openssl

# (To Pull the Docker Images)
dnf install containerd.io -y
systemctl start containerd


cd /datadrive/airgap/images/

# Docker transfer images
# pull the  kubernetes images
ctr image pull k8s.gcr.io/kube-apiserver:v1.30.5
ctr image pull k8s.gcr.io/kube-controller-manager:v1.30.5
ctr image pull k8s.gcr.io/kube-scheduler:v1.30.5
ctr image pull k8s.gcr.io/kube-proxy:v1.30.5
ctr image pull k8s.gcr.io/pause:3.9
ctr image pull k8s.gcr.io/etcd:3.5.16-0
ctr image pull k8s.gcr.io/coredns:1.7.0

# Download calico files
curl -L https://github.com/projectcalico/calico/releases/download/v3.28.2/release-v3.28.2.tgz -O

ctr image export k8s.gcr.io-etcd:3.5.16-0.tar k8s.gcr.io/etcd:3.5.16-0
ctr image export k8s.gcr.io-coredns:1.7.0.tar k8s.gcr.io/coredns:1.7.0 
ctr image export k8s.gcr.io-pause:3.9.tar k8s.gcr.io/pause:3.9
ctr image export k8s.gcr.io-kube-proxy:v1.30.5.tar k8s.gcr.io/kube-proxy:v1.30.5
ctr image export k8s.gcr.io-kube-scheduler:v1.30.5.tar k8s.gcr.io/kube-scheduler:v1.30.5
ctr image export k8s.gcr.io-kube-controller-manager:v1.30.5.tar k8s.gcr.io/kube-controller-manager:v1.30.5
ctr image export k8s.gcr.io-kube-apiserver:v1.30.5.tar k8s.gcr.io/kube-apiserver:v1.30.5 