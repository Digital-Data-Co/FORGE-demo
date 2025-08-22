#!/bin/bash
set -x

# SSHPASS REQUIRED
#USERNAME=dd
#CP_HOSTS="10.50.1.44, 10.50.1.32, 10.50.1.48"
#WRK_HOSTS="10.50.1.x,10.50.1.x"

#for HOSTNAME in ${CP_HOSTS} ; do
#SCRIPT="pwd; ....<scripts below>"
#ssh to server

# END SSHPASS REQUIRED


# K8S INIT - Other Masters

# Disable and Stop firewalld
systemctl disable --now firewalld

# Set FAPolicy in permissive mode and output any denials
fapolicyd — debug-deny —permissive

# Enable kubelet
systemctl --now enable kubelet.service

# Join the cluster, copy file over first.
bash  /home/dd/k8s_init_cp.txt

# Create user .kube directory
mkdir -p /home/dd/.kube
cp -i /etc/kubernetes/admin.conf /home/dd/.kube/config
chown -R dd:dd /home/dd/.kube

# K8S STIG

echo; echo "k8s audit directory and log file"
mkdir -p /var/log/kubernetes/audit
touch /var/log/kubernetes/audit/audit.log

echo; echo "Copy Audit Policy YAML"
scp ./audit_policy.yaml dd@HOST:/etc/kubernetes/audit-policy.yaml

echo; echo "Copy Admission Control Config YAML"
scp ./admissionControlConfig.yaml dd@HOST:/etc/kubernetes/admissionControlConfig.yaml

## CAT I
# V-242386 - The Kubernetes API server must have the insecure port flag disabled. - Implemented in k8s v1.20 https://github.com/kubernetes/kubeadm/issues/2156
# V-242397 - The Kubernetes kubelet staticPodPath must not enable static pods. - WONTFIX

## CAT II
#V-242445 - The Kubernetes component etcd must be owned by etcd. - WONTFIX

echo; echo "CAT I V-242434, CAT II V-245541, CAT II V-242424, CAT II V-242425"
echo protectKernelDefaults: true >> /var/lib/kubelet/config.yaml
echo tlsCipherSuites: [TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384,TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384] >> /var/lib/kubelet/config.yaml
sed -i 's/streamingConnectionIdleTimeout: 0s/streamingConnectionIdleTimeout: 5m/g' /var/lib/kubelet/config.yaml
echo tlsCertFile: /etc/kubernetes/pki/apiserver.crt  >> /var/lib/kubelet/config.yaml
echo tlsPrivateKeyFile: /etc/kubernetes/pki/apiserver.key  >> /var/lib/kubelet/config.yaml

echo; echo "CAT II V-242376 - CAT II V-242409"
sed -i '/- kube-controller-manager/a\\    - --tls-min-version=VersionTLS12' /etc/kubernetes/manifests/kube-controller-manager.yaml 
sed -i '/- kube-controller-manager/a\\    - --profiling=false' /etc/kubernetes/manifests/kube-controller-manager.yaml 

echo; echo "CAT II V-242377 - The Kubernetes Scheduler must use TLS 1.2, at a minimum, to protect the confidentiality of sensitive data during electronic dissemination."
sed -i '/- kube-scheduler/a\\    - --tls-min-version=VersionTLS12' /etc/kubernetes/manifests/kube-scheduler.yaml

echo; echo "CAT II V-242378 - CAT II V-242465 - CAT II V-242464 - CAT II V-242463 - CAT II V-242462 - CAT II V-242461 - CAT II V-242438 - CAT II V-242418 - CAT II V-242403 - CAT II V-242402"
sed -i '/- kube-apiserver/a\\    - --tls-min-version=VersionTLS12' /etc/kubernetes/manifests/kube-apiserver.yaml
sed -i '/- kube-apiserver/a\\    - --audit-policy-file=/etc/kubernetes/audit-policy.yaml' /etc/kubernetes/manifests/kube-apiserver.yaml
sed -i '/- kube-apiserver/a\\    - --tls-cipher-suites=TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384,TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384' /etc/kubernetes/manifests/kube-apiserver.yaml
sed -i '/- kube-apiserver/a\\    - --request-timeout=60s' /etc/kubernetes/manifests/kube-apiserver.yaml
sed -i '/volumes:/a \  - hostPath:\n      path: /etc/kubernetes/audit-policy.yaml\n      type: File\n    name: audit\n  - hostPath:\n      path: /var/log/kubernetes/audit/audit.log\n      type: File\n    name: audit-log' /etc/kubernetes/manifests/kube-apiserver.yaml
sed -i '/volumeMounts:/a \ \ \ \ - mountPath: /etc/kubernetes/audit-policy.yaml\n      name: audit\n      readOnly: true\n \ \ \ - mountPath: /var/log/kubernetes/audit/audit.log\n      name: audit-log\n      readOnly: false' /etc/kubernetes/manifests/kube-apiserver.yaml
sed -i '/- kube-apiserver/a\\    - --audit-log-maxsize=500' /etc/kubernetes/manifests/kube-apiserver.yaml
sed -i '/--service-cluster-ip/a\\    - --audit-log-maxbackup=10' /etc/kubernetes/manifests/kube-apiserver.yaml
sed -i '/--service-cluster-ip/a\\    - --audit-log-maxage=30' /etc/kubernetes/manifests/kube-apiserver.yaml
sed -i '/--service-cluster-ip/a\\    - --audit-log-path=/var/log/kubernetes/audit/audit.log' /etc/kubernetes/manifests/kube-apiserver.yaml
sed -i '/- kube-apiserver/a\\    - --admission-control-config-file=/etc/kubernetes/config/admissionControlConfig.yaml' /etc/kubernetes/manifests/kube-apiserver.yaml
sed -i '/volumes:/a \  - hostPath:\n      path: /etc/kubernetes/config/admissionControlConfig.yaml\n      type: File\n    name: admissioncontrolconfig' /etc/kubernetes/manifests/kube-apiserver.yaml
sed -i '/volumeMounts:/a \ \ \ \ - mountPath: /etc/kubernetes/config/admissionControlConfig.yaml\n      name: admissioncontrolconfig\n      readOnly: true' /etc/kubernetes/manifests/kube-apiserver.yaml

echo; echo "CAT II V-242379 - CAT II V-242380"
sed -i '/- etcd/a\\    - --auto-tls=false' /etc/kubernetes/manifests/etcd.yaml
sed -i '/- etcd/a\\    - --peer-auto-tls=false' /etc/kubernetes/manifests/etcd.yaml


echo; echo "CAT II - V-242406 - The Kubernetes Kubelet Configuration file must be owned by root."
chown root:root /var/lib/kubelet/config.yaml

# POST STIG Fixes
sysctl -w vm.overcommit_memory=1 >> /etc/sysctl.conf
sysctl -w kernel.panic=10 >> /etc/sysctl.conf

# Final Kubelet restart
systemctl daemon-reload && systemctl restart kubelet




