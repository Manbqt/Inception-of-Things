#!/bin/bash

apk update
apk add helm

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

# Chart helm creation
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
helm create mychart
sleep 5

# Replace all templates to only keep the necessary
rm -r mychart/templates/*
cp -f /vagrant_shared/service.yaml mychart/templates/service.yaml
cp -f /vagrant_shared/deployment.yaml mychart/templates/deployment.yaml
cp -f /vagrant_shared/values.yaml mychart/values.yaml
cp -f /vagrant_shared/ingress.yaml mychart/templates/ingress.yaml

# Template verification and displaying
helm template my-release mychart/ -f mychart/values.yaml
# Install all templates
helm install -f mychart/values.yaml mychart mychart/

echo 'source <(kubectl completion bash)' >> .bashrc
echo 'alias k=kubectl' >> .bashrc
echo 'complete -o default -F __start_kubectl k' >> .bashrc

