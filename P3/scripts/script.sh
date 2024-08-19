#!/bin/bash

sudo apt-get update
sudo apt-get install apt-transport-https ca-certificates curl gnupg2 software-properties-common
sudo curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
sudo echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io
sudo systemctl enable docker

# Give permissions
sudo chown $USER /var/run/docker.sock

# K3d installation
curl https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash

# Kubectl installation
# curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
# chmod +x kubectl
# sudo mv kubectl /usr/local/bin/

sudo apt-get install -y apt-transport-https ca-certificates gnupg
if [ ! -f /etc/apt/keyrings ]
then
	echo "file /etc/apt/keyrings is created"
	touch /etc/apt/keyrings
fi

curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
sudo chmod 644 /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo chmod 644 /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y kubectl

# Delete old cluster
k3d cluster delete mycluster
# Create a cluster
k3d cluster create mycluster

export KUBECONFIG_MODE="644"
export KUBECONFIG="/home/$USER/.config/k3d/kubeconfig-mycluster.yaml"

# Set the context
kubectl config delete-context k3d-mycluster
kubectl config set-context k3d-mycluster
kubectl config use-context k3d-mycluster
k3d kubeconfig merge mycluster --kubeconfig-switch-context

# Create a namespace
kubectl create namespace argocd
kubectl apply --wait -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

kubectl create namespace dev

kubectl apply --wait -n argocd -f ../config/appproject.yaml
kubectl apply --wait -n argocd -f ../config/application.yaml
kubectl apply --wait -n dev -f ../config/ingress.yaml

passwd=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
echo "Username: Admin Passwd: $passwd"

kubectl -n argocd port-forward service/argocd-server 8080:80

