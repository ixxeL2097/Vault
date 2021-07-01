# Running Vault with helm on Kubernetes cluster

On OpenShift, execute the following command :

```shell
helm upgrade -i vault --namespace vault vault/ --set ui.enabled=true --set global.openshift=true
```