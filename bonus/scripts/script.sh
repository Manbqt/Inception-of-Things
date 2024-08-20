#!/bin/bash

cd $(dirname $0)

install() {
	curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
	chmod 700 get_helm.sh
	./get_helm.sh
	rm get_helm.sh
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

gitlab() {
	kubectl create namespace gitlab

	helm repo add gitlab https://charts.gitlab.io/
	helm repo update
	helm upgrade --install gitlab gitlab/gitlab \
		-n gitlab \
		--timeout 600s \
		--set global.hosts.domain=gitlab.local \
		--set global.hosts.externalIP=0.0.0.0 \
		--set certmanager-issuer.email=me@gitlab.local

	echo "The password of gitlab root is \`$(kubectl get secret gitlab-gitlab-initial-root-password -n gitlab -ojsonpath='{.data.password}' | base64 --decode)\`"
}

if [ $# -eq 0 ]
then
	install
	install_argocd
	wait_argocd
	argocd
	dev
	gitlab
else
	$1
fi

