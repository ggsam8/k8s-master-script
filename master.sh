#!/bin/bash

### System Update ###
yum -y update

### Add Firewall ###
firewall-cmd --permanent --add-port=6443/tcp
firewall-cmd --permanent --add-port=2379-2380/tcp
firewall-cmd --permanent --add-port=10250/tcp
firewall-cmd --permanent --add-port=10251/tcp
firewall-cmd --permanent --add-port=10252/tcp
firewall-cmd --permanent --add-port=10255/tcp
firewall-cmd --permanent --add-port=8472/udp
firewall-cmd --add-masquerade --permanent
iptables -P FORWARD ACCEPT
modprobe br_netfilter
systemctl restart firewalld
yum -y install policycoreutils-python
semanage port --add --type http_port_t --proto tcp 2379

# Disable swap
swapoff -a
sed -i 's/^\(.*swap.*\)$/#\1/' /etc/fstab 


yum -y install net-tools wget telnet yum-utils device-mapper-persistent-data lvm2


### Add Docker repository.
 yum-config-manager  --add-repo https://download.docker.com/linux/centos/docker-ce.repo

## Install Docker CE.

 yum install docker-ce docker-ce-cli containerd.io -y
 curl -L "https://github.com/docker/compose/releases/download/1.29.5/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

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
vm.swappiness=0
EOF

# Restarting services
systemctl daemon-reload
systemctl restart kubelet



