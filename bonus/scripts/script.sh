#!/bin/bash

cd $(dirname $0)

install_docker() {
	sudo apt-get update
	sudo apt-get install --only-upgrade -y apt-transport-https ca-certificates curl gnupg2 software-properties-common
	if [ ! -f /usr/share/keyrings/docker-archive-keyring.gpg ]
	then
		sudo curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
		sudo echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list
	fi
	sudo apt-get install --only-upgrade -y docker-ce docker-ce-cli containerd.io
	sudo systemctl enable docker

	# Give permissions
	sudo chown $USER /var/run/docker.sock
}

install_k3d() {
	curl https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
}

install_kubectl() {
	sudo apt-get install --only-upgrade -y apt-transport-https ca-certificates gnupg

	# Kubectl installation
	if [ ! -f /etc/apt/keyrings/kubernetes-apt-keyring.gpg ]
	then
		curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
		sudo chmod 644 /etc/apt/keyrings/kubernetes-apt-keyring.gpg
		echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
		sudo chmod 644 /etc/apt/sources.list.d/kubernetes.list
	fi
	sudo apt-get install --only-upgrade -y kubectl
}

install_helm() {
	curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
	chmod 700 get_helm.sh
	./get_helm.sh
	rm get_helm.sh
}

install_argocd() {
	# Delete old cluster
	k3d cluster delete mycluster
	# Create a cluster
	k3d cluster create mycluster --port 8888:80 --agents 2

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

	# Disable server.insecure for argocd
	kubectl patch configmap argocd-cmd-params-cm -n argocd -p '{"data": {"server.insecure": "true"}}'
}

wait_argocd() {
	# Wait for argocd-server to be ready
	kubectl -n argocd wait --for=condition=available --timeout=600s deployment/argocd-server
}

argocd() {
	kubectl apply -n argocd --wait -f ../config/appproject.yaml
	kubectl apply -n argocd --wait -f ../config/application.yaml

	passwd=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
	echo "Username: \`admin\` Password: \`$passwd\`"
}


dev() {
	kubectl create namespace dev
}

ingress() {
	kubectl apply --wait -f ../config/ingress.yaml
}

gitlab() {
	kubectl create namespace gitlab

	helm repo add gitlab https://charts.gitlab.io/
	helm repo update
	helm upgrade --install gitlab gitlab/gitlab \
  		-n gitlab \
  		-f https://gitlab.com/gitlab-org/charts/gitlab/raw/master/examples/values-minikube-minimum.yaml \
  		--set global.hosts.domain=local \
  		--set global.hosts.externalIP=0.0.0.0 \
  		--set global.hosts.https=false


	GITLAB_ROOT_PASSWORD=$(kubectl get secret gitlab-gitlab-initial-root-password -n gitlab -ojsonpath='{.data.password}' | base64 --decode)

	echo "The password of gitlab root is \`${GITLAB_ROOT_PASSWORD}\`"
}

wait_gitlab() {
	kubectl -n gitlab wait --for=condition=available --timeout=600s deployment/gitlab-webservice-default
}

push_gitlab() {
	GITLAB_ROOT_PASSWORD=$(kubectl get secret gitlab-gitlab-initial-root-password -n gitlab -ojsonpath='{.data.password}' | base64 --decode)
	# Set the password for git push
	echo "machine gitlab.local
login root
password ${GITLAB_ROOT_PASSWORD}" > ~/.netrc
	chmod 600 ~/.netrc

	GITLAB_URL="http://gitlab.local"
	REPO_NAME="argocd-mbouquet"

	# Get the access token
	access_token=$(curl --silent --show-error --request POST \
		--form "grant_type=password" --form "username=root" \
		--form "password=$GITLAB_ROOT_PASSWORD" "$GITLAB_URL/oauth/token" \
	| jq -r '.access_token')

	# Create a new project
	curl --silent --show-error --request POST \
		--header "Authorization: Bearer $access_token" \
		--form "name=$REPO_NAME" --form "visibility=public" \
		"$GITLAB_URL/api/v4/projects"

	git clone https://github.com/Manbqt/$REPO_NAME.git /tmp/$REPO_NAME
	cd /tmp/$REPO_NAME
	git remote add gitlab $GITLAB_URL/root/$REPO_NAME.git
	git push gitlab main
	cd -
	rm -rf /tmp/$REPO_NAME
}

if [ $# -eq 0 ]
then
	install_docker
	install_k3d
	install_kubectl
	install_helm
	install_argocd
	wait_argocd
	argocd
	gitlab
	wait_gitlab
	push_gitlab
	dev
	ingress
else
	$1
fi

