#!/bin/bash

cd $(dirname $0)

install () {
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

	sudo apt-get install -y apt-transport-https ca-certificates gnupg
	if [ ! -f /etc/apt/keyrings ]
	then
		echo "file /etc/apt/keyrings is created"
		touch /etc/apt/keyrings
	fi

	# Kubectl installation
	curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
	sudo chmod 644 /etc/apt/keyrings/kubernetes-apt-keyring.gpg
	echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
	sudo chmod 644 /etc/apt/sources.list.d/kubernetes.list
	sudo apt-get update
	sudo apt-get install -y kubectl
}

install_argocd() {
	# Delete old cluster
	k3d cluster delete mycluster
	# Create a cluster
	k3d cluster create mycluster --port 8888:80

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
}

argocd() {
	kubectl apply -n argocd --wait -f ../config/appproject.yaml
	kubectl apply -n argocd --wait -f ../config/application.yaml

	passwd=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
	echo "Username: \`admin\` Password: \`$passwd\`"
}

wait_argocd() {
	# Wait for argocd-server to be ready
	kubectl -n argocd wait --for=condition=available --timeout=600s deployment/argocd-server
}

dev() {
	kubectl create namespace dev

	kubectl apply -n dev --wait -f ../config/dev_ingress.yaml
}

no_install() {
	install_argocd
	wait_argocd
	argocd
	dev
	kubectl -n argocd port-forward service/argocd-server 8080:80
}

if [ $# -eq 0 ]
then
	install
	install_argocd
	wait_argocd
	argocd
	dev
else
	$1
fi

