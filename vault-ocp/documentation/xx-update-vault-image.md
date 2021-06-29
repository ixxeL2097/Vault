[Retour menu principal](../README.md)

## 2. Update Vault

### 2.1 Preparation: Docker image

The first thing to do is to grab to newer Vault docker image. Let's work with Vault 1.4.1 :

```console
[root@workstation ~ ]$ docker pull vault:1.4.1
1.4.1: Pulling from library/vault
21c83c524219: Pull complete 
aeddf51eb574: Pull complete 
719720d4ff92: Pull complete 
c48e6ba784e7: Pull complete 
0c90a552e78f: Pull complete 
Digest: sha256:8b56a8bc7fe22379723b0313bd78668389bfa93e693c4f7d574a23d1efcab23c
Status: Downloaded newer image for vault:1.4.1
docker.io/library/vault:1.4.1
```

Now, just as for the installation phase, tag & push your new image to the OpenShift internal registry. First tag the image :

```console
[root@workstation ~ ]$ docker tag vault:1.4.1 default-route-openshift-image-registry.apps.ocp4-dev5.devibm.local/hashicorp/vault:1.4.1
```

Then login to OpenShift console and internal registry :

```console
[root@workstation ~ ]$ oc login --insecure-skip-tls-verify=true https://api.ocp4-dev5.devibm.local:6443 -u kubeadmin -p <password>
Login successful.

You have access to 61 projects, the list has been suppressed. You can list all projects with 'oc projects'

Using project "default".
[root@workstation ~ ]$ docker login -u kubeadmin -p $(oc whoami -t) default-route-openshift-image-registry.apps.ocp4-dev5.devibm.local
Login Succeeded
```

And finally push your image :

```console
[root@workstation ~ ]$ docker push default-route-openshift-image-registry.apps.ocp4-dev5.devibm.local/hashicorp/vault:1.4.1
The push refers to repository [default-route-openshift-image-registry.apps.ocp4-dev5.devibm.local/hashicorp/vault]
0f84a354b60a: Pushed 
1742891a5fe1: Pushed 
27c4aa52f5f7: Pushed 
73628a861044: Pushed 
1b3ee35aacca: Pushed 
1.4.1: digest: sha256:a26845ac976fa471f1a373eba30d2e7b42ddd344c9aef094fddfad091bbd9941 size: 1363
```

### 2.2 Preparation: PV and annotations

Now that your new image is uploaded, your need to verify a few things before starting to update. 

If you have set update strategy to ```rollingUpdate``` then you need to verify that your PV (if you use one) is set to ```ReadWriteMany``` AccessMode. If you are on ```ReadWriteOnce``` you need to patch it in order to provide access to your new pod during the update process.

Just edit your PV and replace ```ReadWriteOnce``` by ```ReadWriteMany``` :

```console
[root@workstation ~ ]$ oc edit pv <pv-name>
```

once done, you are ready to update your vault app. You need to patch the ```deployment``` object to make the update effective. Just modify the yaml file ```015-Deployment-vault.yaml``` with the proper image version on the following line :

```diff
     spec:
       containers:
!      - image: image-registry.openshift-image-registry.svc:5000/hashicorp/vault:1.4.1
```

You should also add a comment to describe the reason of the update by adding the following line in the yaml file :

```diff
   template:
     metadata:
       labels:
         app.kubernetes.io/instance: vault
         app.kubernetes.io/name: vault
+      annotations:
+        kubernetes.io/change-cause: "update vault to 1.4.1"
```

This way you can track more easily your update changes. 

### 2.3 Proceed update

Once all modifications have been done, you just have to apply it to your OpenShift cluster :

```console
[root@workstation ~ ]$ oc apply -f 015-Deployment-vault.yaml 
deployment.apps/vault configured
```

You can track update status with following commands :

- ```oc rollout status deployment.apps/vault```
- ```oc get pods```

If for whatever reason something goes wrong and you want to rollback to the previous version, just hit that command :

```console
[root@workstation ~ ]$ oc rollout undo deployment.apps/vault 
.deployment.apps/vault rolled back
```

The command ```oc get pods``` should output the following line :

```console
[root@workstation ~ ]$ oc get pods
NAME                     READY   STATUS    RESTARTS   AGE
vault-74b9999447-hst6m   0/1     Running   0          17s
vault-7c5d4f6bf7-qxmxc   1/1     Running   0          35d
```

Your new pod is running but still not ready. And if you ask OpenShift for a description, you should see the following lines :

```console
[root@workstation ~ ]$ oc describe pod vault-74b9999447-hst6m
...
Events:
  Type     Reason                  Age   From                     Message
  ----     ------                  ----  ----                     -------
  Normal   Scheduled               25s   default-scheduler        Successfully assigned hashicorp/vault-74b9999447-hst6m to worker-dev5-0
  Normal   SuccessfulAttachVolume  25s   attachdetach-controller  AttachVolume.Attach succeeded for volume "pvc-39450f72-799f-11ea-8924-00505681e1fd"
  Normal   Pulled                  13s   kubelet, worker-dev5-0   Container image "image-registry.openshift-image-registry.svc:5000/hashicorp/vault:1.4.1" already present on machine
  Normal   Created                 12s   kubelet, worker-dev5-0   Created container vault
  Normal   Started                 12s   kubelet, worker-dev5-0   Started container vault
  Warning  Unhealthy               7s    kubelet, worker-dev5-0   Readiness probe failed: Key                Value
---                -----
Seal Type          shamir
Initialized        true
Sealed             true
Total Shares       1
Threshold          1
Unseal Progress    0/1
Unseal Nonce       n/a
Version            1.4.1
HA Enabled         false
```

Everything is normal you just have to unseal your new pod as described on the output to make it ready. Grab your ```unseal key``` and proceed to unsealing :

```console
[root@workstation ~ ]$ oc rsh vault-74b9999447-hst6m
[root@vault-container ~ ]$ vault operator unseal --tls-skip-verify $KEY
Key             Value
---             -----
Seal Type       shamir
Initialized     true
Sealed          false
Total Shares    1
Threshold       1
Version         1.4.1
Cluster Name    vault-cluster-b5d3da19
Cluster ID      1001187c-4ab9-492f-8c03-25267cb7bebb
HA Enabled      false
~ $ ⏎ 
```

Once done you can now verify pods and verify the old pod is being deleted :

```console
[root@workstation ~ ]$ oc get pods
NAME                     READY   STATUS        RESTARTS   AGE
vault-74b9999447-hst6m   1/1     Running       0          2m57s
vault-7c5d4f6bf7-qxmxc   0/1     Terminating   0          36d
```

Everything should be working now. You can check rollout history by executing following command :

```console
[root@workstation ~ ]$ oc rollout history deployment.apps/vault
deployment.apps/vault 
REVISION  CHANGE-CAUSE
1         <none>
2         update vault to 1.4.1
```


---------------------------------------------------------------------------------------------------------------------------------

[Retour menu principal](../README.md)


