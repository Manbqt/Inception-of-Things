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

echo 'source <(kubectl completion bash)' >> ~/.bashrc
echo 'complete -o default -F __start_kubectl k' >> ~/.bashrc
echo "alias k='kubectl'" >> ~/.bashrc

sleep 5

for i in {1..3}
do
	kubectl apply -f /vagrant_shared/service_app$i.yaml --validate=false
	kubectl apply -f /vagrant_shared/deployment_app$i.yaml --validate=false
done
