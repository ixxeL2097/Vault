# Running Vault with podman pod

To run a vault pod with podman you can execute the following command:

```shell
podman run --pod new:pod-vault \
	       --cap-add=CAP_IPC_LOCK \
           -ti -d -v $HOST_PATH:/vault:z \
	       --name vault \
	       -p 8200:8200 \
	       vault:latest \
           vault server -config=/vault/config/vault.json
```

and then check :

```console
[fred@ ~/D/T/d/vault-compose]$ podman pod ls
POD ID        NAME       STATUS   CREATED        INFRA ID      # OF CONTAINERS
94be48257a71  pod-vault  Running  5 seconds ago  9ddc462dd05d  2
```

```console
[fred@ ~/D/T/d/vault-compose]$ podman ps
CONTAINER ID  IMAGE                           COMMAND               CREATED         STATUS             PORTS                   NAMES
9ddc462dd05d  k8s.gcr.io/pause:3.5                                  13 seconds ago  Up 13 seconds ago  0.0.0.0:8200->8200/tcp  94be48257a71-infra
5a3e353da84d  docker.io/library/vault:latest  vault server -con...  13 seconds ago  Up 13 seconds ago  0.0.0.0:8200->8200/tcp  vault
```

You can now generate a yaml file from this pod :

```shell
podman generate kube pod-vault >> vault-pod.yaml
```

Kill the pod and apply the yaml to check if it works properly:

```
podman pod kill --all
podman pod rm --all

podman play kube vault-pod.yaml
```