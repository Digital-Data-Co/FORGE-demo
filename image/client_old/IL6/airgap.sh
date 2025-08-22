#!/bin/bash

#Docker Download
mkdir -p ./airgap/images
mkdir -p ./airgap/rpms
cd ./airgap/images/

#dnf install -y yum-utils
#yum-config-manager --add-repo https://download.docker.com/linux/rhel/docker-ce.repo
#dnf install --downloadonly --downloaddir=/datadrive/airgap/images/ docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin container-selinux kubelet kubeadm kubectl conntrack-tools cri-tools iptables-nft kubernetes-cni libnetfilter_cthelper libnetfilter_cttimeout libnetfilter_queue libnftnl socat iproute openscap-scanner scap-security-guide libtool-ltdl libxslt openscap xmlsec1 xmlsec1-openssl

#Kubernetes Download

cat <<EOF | tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.32/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.32/rpm/repodata/repomd.xml.key
exclude=kubelet kubeadm kubectl cri-tools kubernetes-cni
EOF

# (To Pull the Docker Images)
#dnf install containerd.io -y
#systemctl start containerd

# SCAP Files
#curl -L https://dl.dod.cyber.mil/wp-content/uploads/stigs/zip/scc-5.10_rhel9_x86_64_bundle.zip -O
#curl -L https://dl.dod.cyber.mil/wp-content/uploads/stigs/zip/U_RHEL_9_V2R1_STIG_SCAP_1-3_benchmark.zip -O
#curl -L https://dl.dod.cyber.mil/wp-content/uploads/stigs/zip/U_Kubernetes_V2R1_STIG_SCAP_1-3_Benchmark.zip -O


cd ./airgap/images/

# Docker transfer images
# pull the  kubernetes images
docker image pull registry.k8s.io/kube-apiserver:v1.32.2
docker image pull registry.k8s.io/kube-controller-manager:v1.32.2
docker image pull registry.k8s.io/kube-scheduler:v1.32.2
docker image pull registry.k8s.io/kube-proxy:v1.32.2
docker image pull registry.k8s.io/pause:3.9
docker image pull registry.k8s.io/etcd:3.5.21-0
docker image pull registry.k8s.io/coredns/coredns:v1.12.0

# Download calico files
curl -L https://github.com/projectcalico/calico/releases/download/v3.29.3/release-v3.29.3.tgz -O
docker save -o registry.k8s.io-etcd-3.5.21-0.tar registry.k8s.io/etcd:3.5.21-0
docker save -o registry.k8s.io-coredns:1.12.0.tar registry.k8s.io/coredns/coredns:v1.12.0
docker save -o registry.k8s.io-pause:3.9.tar registry.k8s.io/pause:3.9
docker save -o registry.k8s.io-kube-proxy:v1.32.2.tar registry.k8s.io/kube-proxy:v1.32.2
docker save -o registry.k8s.io-kube-scheduler:v1.32.2.tar registry.k8s.io/kube-scheduler:v1.32.2
docker save -o registry.k8s.io-kube-controller-manager:v1.32.2.tar registry.k8s.io/kube-controller-manager:v1.32.2
docker save -o registry.k8s.io-kube-apiserver:v1.32.2.tar registry.k8s.io/kube-apiserver:v1.32.2 

cd ..
tar -czvf airgap.tar.gz .