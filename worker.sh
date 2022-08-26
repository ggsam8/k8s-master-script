#!/bin/bash

### System Update ###
yum -y update

### Add Firewall ###
firewall-cmd --permanent --add-port=10250/tcp
firewall-cmd --permanent --add-port=10255/tcp
firewall-cmd --permanent --add-port=8472/udp
firewall-cmd --permanent --add-port=30000-32767/tcp
firewall-cmd --add-masquerade --permanent
iptables -P FORWARD ACCEPT
modprobe br_netfilter
systemctl restart firewalld

echo '1' > /proc/sys/net/bridge/bridge-nf-call-iptables
sysctl -w net.ipv4.ip_forward=1

# Disable swap
swapoff -a
sed -i 's/^\(.*swap.*\)$/#\1/' /etc/fstab 

yum -y install net-tools wget telnet yum-utils device-mapper-persistent-data lvm2

### Add Docker repository.
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

## Install Docker CE.
yum install docker-ce docker-ce-cli containerd.io -y

## Create /etc/docker directory.
mkdir /etc/docker

# Setup daemon.
cat > /etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2",
  "storage-opts": [
    "overlay2.override_kernel_check=true"
  ]
}
EOF

mkdir -p /etc/systemd/system/docker.service.d

# Restart Docker
systemctl daemon-reload
systemctl enable docker
systemctl restart docker



# Install kuberentes packages
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF

yum -y install kubectl-1.19.8 kubelet-1.19.8 kubeadm-1.19.8
systemctl  restart kubelet && systemctl enable kubelet

# Enable IP Forwarding
echo '1' > /proc/sys/net/bridge/bridge-nf-call-iptables
cat <<EOF >  /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF


# Restarting services
systemctl daemon-reload
systemctl restart kubelet

