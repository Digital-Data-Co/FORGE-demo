# !/bin/bash
firewall-cmd --ipv4 --zone=drop --add-service=http --permanent --reload
firewall-cmd --ipv4 --zone=drop --add-service=https --permanent --reload #HTTPS
firewall-cmd --ipv4 --zone=drop --add-service=https --add-port=6443 --permanent --reload #kubernetes api
firewall-cmd --ipv4 --zone=drop --add-port=179/tcp --permanent --reload  # calico BGP
firewall-cmd --ipv4 --zone=drop --add-service=https --permanent --reload     # HTTPS
firewall-cmd --ipv4 --zone=drop --add-port=2379/tcp --permanent --reload     # etcd client
firewall-cmd --ipv4 --zone=drop --add-port=2380/tcp --permanent --reload     # etcd peer
firewall-cmd --ipv4 --zone=drop --add-port=6443/tcp --permanent --reload    # kubernetes api
firewall-cmd ---ipv4 --zone=drop --add-port=10250/tcp --permanent --reload   # kubelet services
firewall-cmd ---ipv4 --zone=drop  --add-port=30000-32767 --protocol=tcp/udp --permanent --reload   # NodePort
firewall-cmd --set-default-zone=drop --permanent --reload

echo "net.bridge.bridge-nf-call-iptables  = 1" >> /etc/sysctl.conf
echo "net.ipv4.ip_forward                 = 1" >> /etc/sysctl.conf
echo "net.bridge.bridge-nf-call-ip6tables = 1" >> /etc/sysctl.conf
sysctl --system