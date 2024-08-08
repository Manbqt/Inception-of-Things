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

export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

echo 'source <(kubectl completion bash)' >> ~/.bashrc
echo 'complete -o default -F __start_kubectl k' >> ~/.bashrc
echo "alias k='kubectl'" >> ~/.bashrc

sleep 5

helm create mychart
chmod 666 /etc/rancher/k3s/k3s.yaml

sleep 5

cp -f /vagrant_shared/service.yaml mychart/templates/service.yaml
cp -f /vagrant_shared/deployment.yaml mychart/templates/deployment.yaml
cp -f /vagrant_shared/values.yaml mychart/values.yaml

helm template my-release mychart/ -f mychart/values.yaml

sleep 5


helm install -f mychart/values.yaml test mychart/

# for i in {1..3}
# do
# 	helm install -f P2/values.yaml test$i P2/
# 	# kubectl apply -f /vagrant_shared/service_app$i.yaml --validate=false
# 	# kubectl apply -f /vagrant_shared/deployment_app$i.yaml --validate=false
# done
