# Part1

In order to create machines we have used `vagrant`.

## What is Vagrant ?

Vagrant is a software to create environment of virtual machines. It is a `wrapper` of virtualization software like `virtualbox` or `vmware`.
In our case we are using `virtualbox`.  
To create a configuration we have used file named [vagrantfile](https://developer.hashicorp.com/vagrant/docs/vagrantfile). 

For each machines we have created a `script bash` to install the necessaries like `k3s` or `kubectl`. This script are integrated in the `vagrantfile`.  

## What is k3s ?

K3s is a light distribution of [kubernetes](https://blog.stephane-robert.info/docs/conteneurs/orchestrateurs/kubernetes/introduction/). So it is a software to handle containers. Kubernetes (K8s) is a full lifecycle management (deployment, scaling etc.).  
It's a modular approach, have a `master node` and `worker node`.  
The `master` is the handler, it dispatches actions/activities to workers to maintain the desired environment.  
The `worker` is an executor. It executes the containers as specified in the configuration. It send informations about his activities to the `master`.  

### k3s installation

To install k3s software we can use [environment variable](https://docs.k3s.io/reference/env-variables) to [configure](https://docs.k3s.io/installation/configuration#configuration-with-install-script) it.
