# Part3

In this part, we want deployed automatically our service `wil-playground`.

## K3D
It's a wrapper to run K3S in `docker`.

## ArgoCD
It's a GitOps tool to deploy applications in Kubernetes.
To specify which project we want deployed, we have used `application` and `appproject` files.  
Each pod, application and project can be managed using argocd interface.  
It monitors your Git repositories and automatically applies changes to your Kubernetes cluster when a commit is made.

