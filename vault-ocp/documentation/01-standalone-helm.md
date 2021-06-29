[Retour menu principal](../README.md)

## 1. Standalone install on Openshift cluster
### Install Vault with helm

To install Vault in your cluster, the easiest way is to use helm chart from Hashicorp. Available here : 

- https://github.com/hashicorp/vault-helm

Add your helm repo:

```console
[root@VLPCLA01 vault-install]# helm repo add hashicorp https://helm.releases.hashicorp.com
"hashicorp" has been added to your repositories
[root@VLPCLA01 vault-install]# helm repo update
Hang tight while we grab the latest from your chart repositories...
...Successfully got an update from the "hashicorp" chart repository
Update Complete. ⎈ Happy Helming!⎈ 
```

And download the chart localy :

```console
[root@VLPCLA01 vault-install]# helm fetch --untar hashicorp/vault
```

Once downloaded, you can create your namespace/project in your cluster to deploy your Vault instance:

```
oc new-project vault
```

In case you are working in an offline environment, you have to upload 2 images to your openshift cluster internal registry. 1st image is for vault, and 2nd image is for injector :
- vault
- hashicorp/vault-k8s

Use `skopeo` or `docker` to push images then check it processed correctly :

```console
[root@VLPCLA01 vault-install]# oc get is
NAME        IMAGE REPOSITORY                                                                                        TAGS    UPDATED
vault       default-route-openshift-image-registry.apps.ocp-infra-dc6.prodibm.wcorp.carrefour.com/vault/vault       1.5.4   26 hours ago
vault-k8s   default-route-openshift-image-registry.apps.ocp-infra-dc6.prodibm.wcorp.carrefour.com/vault/vault-k8s   0.5.0   9 hours ago
```

Before deploying with helm chart, don't forget to update your `values.yaml` with private registry image reference :

```yaml
server:
  image:
    repository: "image-registry.openshift-image-registry.svc:5000/vault/vault"
    tag: "1.5.4"
    pullPolicy: IfNotPresent
```

```yaml
injector:
  enabled: true
  metrics:
    enabled: false
  externalVaultAddr: ""
  image:
    repository: "image-registry.openshift-image-registry.svc:5000/vault/vault-k8s"
    tag: "0.5.0"
    pullPolicy: IfNotPresent
```

And then deploy Vault. For Openshift installation, you need to specify the `global.openshift=true` flag to handle proper SCC creation. 

```shell
helm upgrade -i vault --namespace vault vault/ --set ui.enabled=true --set global.openshift=true
```

Once execute Vault should start and be `Running` but not `Ready`. Vault needs to be initialized and unsealed before working properly. First `rsh` into pod and then use the following commands to do it :

```shell
oc rsh vault-0
```

When you rsh Vault pod, your need to export your Root token before executing commands :
```shell
export VAULT_TOKEN=<root-token>
```

Initialize Vault :

```shell
vault operator init --tls-skip-verify -key-shares=1 -key-threshold=1
```

**Save the value of the Unseal Key and Root token carefuly.** 

unseal Vault :

```shell
vault operator unseal --tls-skip-verify <unseal-key>
```


# Interesting links

- https://medium.com/faun/mount-ssl-certificates-in-kubernetes-pod-with-secret-8aca220896e6
- https://rancher.com/docs/rancher/v2.x/en/installation/resources/encryption/tls-secrets/

