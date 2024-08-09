# Part2

In this section, we create services and deploy them so that they are available outside the cluster.  

To create `services`, `deployments` and `ingress` we have used `chart helm`.  

## Chart Helm

A chart is an `Helm package`. It contains all necessaries to execute an application/service inside the cluster.  
Because we have 3 applications who are almost identical, we have used templates. Templates are pattern in which `values` can be different depending on application.  
Values are stored in `values.yaml` and are called in each `yaml` file using `{{ .valueName }}`.  

## [Service](https://kubernetes.io/docs/concepts/services-networking/service/)

All services can be configure using `service.yaml` file.  
We have used a docker image named `paulbouwer/hello-kubernetes:1.10` who is exposed on port 8080.  
To customize message we can use an environment variable named `MESSAGE`.   

```bash
mbouquetS:~$ kubectl get services
NAME         TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
app-one      ClusterIP   10.43.19.91     <none>        80/TCP    3m24s
app-three    ClusterIP   10.43.143.240   <none>        80/TCP    3m24s
app-two      ClusterIP   10.43.24.76     <none>        80/TCP    3m24s
kubernetes   ClusterIP   10.43.0.1       <none>        443/TCP   3m28s
```

## [Deployment](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)

All deployment can be configure using `deployment.yaml` file.  

```bash
mbouquetS:~$ kubectl get deployments
NAME        READY   UP-TO-DATE   AVAILABLE   AGE
app-one     1/1     1            1           3m50s
app-three   3/3     3            3           3m50s
app-two     1/1     1            1           3m50s
```

## [Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/)

Ingress is a type who available the communication outside the cluster.  
Because we must get access outside cluster, we must create an `ingress`. It is configure using `ingress.yaml`.  

```bash
mbouquetS:~$ kubectl get ingress
NAME        CLASS    HOSTS               ADDRESS          PORTS   AGE
myingress   <none>   app1.com,app2.com   192.168.56.110   80      4m13s
```
