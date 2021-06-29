
### Tips & Tricks
#### Sealing

if for some reason, your vault instance is rebooted, or your cluster is rebooted, you will end with a **sealed Vault instance**. You need to unseal it each time your pod is rebooted.

Symptoms are like following : 

```console
[root@frvmt0002754 ~]# oc get pod
NAME                     READY   STATUS    RESTARTS   AGE
vault-5c87bc975b-cnkw9   0/1     Running   0          2m28s
```

```console
[root@frvmt0002754 ~]# oc describe pod vault-5c87bc975b-cnkw9
[...]
Events:
  Type     Reason     Age                      From                    Message
  ----     ------     ----                     ----                    -------
  Normal   Scheduled  24s                      default-scheduler       Successfully assigned hashicorp/vault-5c87bc975b-cnkw9 to worker-int1-1
  Normal   Pulled     15s                      kubelet, worker-int1-1  Container image "image-registry.openshift-image-registry.svc:5000/hashicorp/vault:1.3.2" already present on machine
  Normal   Created    14s                      kubelet, worker-int1-1  Created container vault
  Normal   Started    14s                      kubelet, worker-int1-1  Started container vault
  Warning  Unhealthy  <invalid> (x15 over 9s)  kubelet, worker-int1-1  Readiness probe failed: Key                Value
---                -----
Seal Type          shamir
Initialized        true
Sealed             true
Total Shares       1
Threshold          1
Unseal Progress    0/1
Unseal Nonce       n/a
Version            1.3.2
HA Enabled         false
```

You can see here that the eadiness probe failed and pod is marked as running but not ready. That is because you can see that your pod is mentioned as `Sealed : True`.

In order to fix this, you just have to unseal vault as in the installation procedure:

```console
[root@frvmt0002754 ~]# oc rsh vault-5c87bc975b-cnkw9
[root@container]$ vault operator unseal --tls-skip-verify $KEY
Key             Value
---             -----
Seal Type       shamir
Initialized     true
Sealed          false
Total Shares    1
Threshold       1
Version         1.3.2
Cluster Name    vault-cluster-e24d0a25
Cluster ID      0f59f997-d513-e0a3-876a-4e3bbdc4e907
HA Enabled      false
[root@container]$ exit
```

Then you can check you container is running and ready :

```console
[root@frvmt0002754 ~]# oc get pod
NAME                     READY   STATUS    RESTARTS   AGE
vault-5c87bc975b-cnkw9   1/1     Running   0          10m
```


#### PV/PVC

After deleting a PVC with ```oc delete pvc <pvc-name>```, if PVC deletion is stuck, just check ```kubectl describe pvc <pvc-name> | grep Finalizers``` :

```console
[root@workstation ~ ]$ kubectl describe pvc vault-storage | grep Finalizers
Finalizers:    [kubernetes.io/pvc-protection]
```

Then force PVC deletion by executing ```kubectl patch pvc <pvc-name> -p '{"metadata":{"finalizers": []}}' --type=merge``` :

```console
[root@workstation ~ ]$ kubectl patch pvc vault-storage -p '{"metadata":{"finalizers": []}}' --type=merge
persistentvolumeclaim/vault-storage patched
```

**P.S: you can do the same for PV deletion**

When PV are in ```Released``` state :

```console
[root@workstation ~ ]$ oc get pv
NAME                        CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS     CLAIM                    STORAGECLASS             REASON   AGE
pvc-39450f72-00505681e1fd   10Gi       RWX            Retain           Released   hashicorp/vault-storage  trident-storage-retain            35d
```

Just set them to ```Available``` state with the command ```kubectl patch pv <pv-name> -p '{"spec":{"claimRef": null}}'```:

```bash
[root@workstation ~ ]$ kubectl patch pv pvc-39450f72-00505681e1fd -p '{"spec":{"claimRef": null}}'
persistentvolume/pvc-39450f72-00505681e1fd patched
```

```console
[root@workstation ~ ]$ oc get pv
NAME                        CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS      CLAIM   STORAGECLASS             REASON   AGE
pvc-39450f72-00505681e1fd   10Gi       RWX            Retain           Available           trident-storage-retain            35d
```
