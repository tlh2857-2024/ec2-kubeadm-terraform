#!/bin/bash
# bootstrap.sh

# Update system and install dependencies
sudo apt update -y
sudo apt install -y apt-transport-https ca-certificates curl gnupg lsb-release

# Install Docker
# Reference: https://docs.docker.com
curl -fsSL https://download.docker.com | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update -y
sudo apt install -y docker-ce docker-ce-cli containerd.io

# Configure containerd
sudo mkdir -p /etc/containerd
sudo containerd config default | sudo tee /etc/containerd/config.toml
# Update SystemdCgroup to true as recommended for Kubernetes
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
sudo systemctl restart containerd

# Install Kubernetes components (kubelet, kubeadm, kubectl)
# Reference: https://kubernetes.io
curl -s https://packages.cloud.google.com | sudo gpg --dearmor -o /usr/share/keyrings/kubernetes-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list > /dev/null
sudo apt update -y
sudo apt install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

# Initialize the Kubernetes control plane
sudo kubeadm init --pod-network-cidr=10.244.0.0/16 # Using Calico's default CIDR

# Configure kubectl for the ubuntu user
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Install a Pod Network Add-on (Calico)
kubectl apply -f https://docs.tigera.io

# Taint the master node so pods can be scheduled on it (single node cluster)
kubectl taint nodes --all node-role.kubernetes.io/control-plane-
