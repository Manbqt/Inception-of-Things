#!/bin/bash

apt update
apt install curl

#Docker installation
sudo apt install apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable"
apt-cache policy docker-ce
sudo apt install docker-ce

# Give permissions
sudo groupadd -f docker
sudo usermod -aG docker $USER
newgrp docker << EOF
echo "Group Docker reloaded."
EOF

# K3d installation
curl https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash

# Kubectl installation
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
# sudo mv kubectl /usr/local/bin/

# Delete old cluster
k3d cluster delete mycluster
# Create a cluster
k3d cluster create mycluster

export KUBECONFIG_MODE="644"
export KUBECONFIG=/home/manon/.config/k3d/kubeconfig-mycluster.yaml

# Set the context
kubectl config delete-context k3d-mycluster
kubectl config set-context k3d-mycluster
kubectl config use-context k3d-mycluster
k3d kubeconfig merge mycluster --kubeconfig-switch-context

# Create a namespace
kubectl create namespace argocd
kubectl create namespace dev

