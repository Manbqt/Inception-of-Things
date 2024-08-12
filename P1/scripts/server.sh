#!/bin/bash

apk update

# Kubectl installation
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl

# Use environment variables to configure the installation
# Permission given during the installation
export K3S_KUBECONFIG_MODE="644"
# Installation as a `server`, listened IP address and interface used
export INSTALL_K3S_EXEC="server --bind-address=$1 --flannel-iface=eth1"

curl -sfL https://get.k3s.io | sh -
while [ ! -f /var/lib/rancher/k3s/server/token ]
do
	sleep 1
done
echo "k3s is installed"

# Token used to create link with the worker
cp /var/lib/rancher/k3s/server/token /vagrant_shared/

echo 'source <(kubectl completion bash)' >> .bashrc
echo 'alias k=kubectl' >> .bashrc
echo 'complete -o default -F __start_kubectl k' >> .bashrc
