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


# K8S INIT - Worker Nodes

# Disable and Stop firewalld
systemctl disable --now firewalld

# Set FAPolicy in permissive mode and output any denials
fapolicyd — debug-deny —permissive

# Enable kubelet
systemctl --now enable kubelet.service

# Join the cluster, copy file over first.
bash  /home/dd/k8s_init_worker.txt # (remove --control-plane)


echo; echo "CAT II - V-242406 - The Kubernetes Kubelet Configuration file must be owned by root."
chown root:root /var/lib/kubelet/config.yaml

# POST STIG Fixes
sysctl -w vm.overcommit_memory=1 >> /etc/sysctl.conf
sysctl -w kernel.panic=10 >> /etc/sysctl.conf

# Final Kubelet restart
systemctl daemon-reload && systemctl restart kubelet




