#!/bin/bash

sudo apt update

# Create a new directory for APT keyrings with permissions
sudo mkdir -m 755 /etc/apt/keyrings

# Update APT repositories
sudo apt update

# Install necessary packages for APT over HTTPS and other utilities
sudo apt install -y apt-transport-https ca-certificates curl gpg

# Import the GPG key for Kubernetes packages
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

# Add the Kubernetes APT repository
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

# Update APT repositories
sudo apt update

# Install Kubernetes components and mark them to hold updates
sudo apt install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

# Disable swap - required for Kubernetes
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
sudo swapoff -a
sudo mount -a
free -h

# Load necessary kernel modules
sudo modprobe overlay
sudo modprobe br_netfilter

# Set sysctl parameters required by Kubernetes
sudo tee /etc/sysctl.d/kubernetes.conf<<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF

sudo tee /etc/modules-load.d/containerd.conf <<EOF
overlay
br_netfilter
EOF

sudo sysctl --system

# Install Docker dependencies
sudo apt install -y curl gnupg2 software-properties-common apt-transport-https ca-certificates

# Add Docker’s official GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

# Add Docker repository
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

# Install containerd
sudo apt update
sudo apt install -y containerd.io

# Configure containerd and start service
sudo su -c "mkdir -p /etc/containerd && containerd config default>/etc/containerd/config.toml"
sudo systemctl restart containerd 
sudo systemctl enable containerd
systemctl status containerd

# Check loaded modules
lsmod | grep br_netfilter

# Enable kubelet service
sudo systemctl enable kubelet


