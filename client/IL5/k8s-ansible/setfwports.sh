#!/bin/bash

# Variables (Update as per your environment)
CLUSTER_CIDR="192.168.0.0/16"  # Replace with your cluster CIDR
NODE_CIDR="10.21.1.0/24"        # Replace with your node CIDR
INTERFACE_NAME="eth0"          # Replace with the Kubernetes network interface

# Step 1: Set Default Zone to Drop
echo "Setting default firewalld zone to 'drop'..."
firewall-cmd --set-default-zone=drop

# Step 2: Create a Kubernetes Zone
echo "Creating 'kubernetes' firewalld zone..."
firewall-cmd --permanent --new-zone=kubernetes

# Step 3: Associate Interface with Kubernetes Zone
echo "Associating interface ${INTERFACE_NAME} with 'kubernetes' zone..."
firewall-cmd --permanent --zone=drop --remove-interface=eth0
firewall-cmd --permanent --zone=kubernetes --add-interface=${INTERFACE_NAME}
firewall-cmd --permanent --zone=kubernetes --add-interface=vxlan.calico
firewall-cmd --permanent --zone=kubernetes --add-interface="cali+"

# Step 4: Open Required Kubernetes Ports
echo "Opening Kubernetes and Calico required ports..."
firewall-cmd --permanent --zone=kubernetes --add-port=6443/tcp    # API Server
firewall-cmd --permanent --zone=kubernetes --add-port=10250/tcp   # Kubelet
firewall-cmd --permanent --zone=kubernetes --add-port=10255/tcp   # Kubelet Read-Only
firewall-cmd --permanent --zone=kubernetes --add-port=10251/tcp   # Scheduler
firewall-cmd --permanent --zone=kubernetes --add-port=10252/tcp   # Controller Manager
firewall-cmd --permanent --zone=kubernetes --add-port=2379-2380/tcp # Etcd
firewall-cmd --permanent --zone=kubernetes --add-port=53/tcp # DNS
firewall-cmd --permanent --zone=kubernetes --add-port=53/udp # DNS
firewall-cmd --permanent --zone=kubernetes --add-port=30000-32767/tcp # NodePorts
firewall-cmd --permanent --zone=kubernetes --add-port=3000/tcp # DigitalData

# Services
firewall-cmd --permanent --zone=kubernetes --add-service=ssh # SSH
firewall-cmd --permanent --zone=kubernetes --add-service=http # HTTP
firewall-cmd --permanent --zone=kubernetes --add-service=https # HTTPS


# Calico VXLAN Ports
firewall-cmd --permanent --zone=kubernetes --add-port=4789/udp    # VXLAN
firewall-cmd --permanent --zone=kubernetes --add-port=179/tcp     # BGP (if used)

# Step 5: Allow Cluster and Node Traffic
echo "Allowing cluster and node traffic..."
firewall-cmd --permanent --zone=kubernetes --add-rich-rule="rule family=ipv4 source address=${CLUSTER_CIDR} accept"
firewall-cmd --permanent --zone=kubernetes --add-rich-rule="rule family=ipv4 source address=${NODE_CIDR} accept"

# Step 6: Enable IP Masquerading
echo "Enabling masquerading in 'kubernetes' zone..."
firewall-cmd --permanent --zone=kubernetes --add-masquerade

# Step 7: Reload firewalld
echo "Reloading firewalld configuration..."
firewall-cmd --reload

# Final Step: Verify Settings
echo "Verifying 'firewalld' settings..."
firewall-cmd --list-all --zone=kubernetes
firewall-cmd --get-default-zone
firewall-cmd --get-active-zones

echo "Firewalld configuration for Kubernetes and Calico with VXLAN mode completed."


echo "net.bridge.bridge-nf-call-iptables  = 1" >> /etc/sysctl.conf
echo "net.ipv4.ip_forward                 = 1" >> /etc/sysctl.conf
echo "net.bridge.bridge-nf-call-ip6tables = 1" >> /etc/sysctl.conf
sysctl --system