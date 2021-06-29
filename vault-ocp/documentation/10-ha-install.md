## 3. HA installation

To install in HA mode, you need a backend. Hashicorp provide Consul as its own backend and we will install Vault with Consul in this procedure.

### 3.1 Install Consul HA

You can download official Hashicorp helm chart Consul from `https://github.com/hashicorp/consul-helm` :

```shell
helm repo add hashicorp https://helm.releases.hashicorp.com
helm repo update
helm fetch --untar hashicorp/consul
```

For OpenShift installation you need to add `SecurityConstraints` to your service account in order to deploy Consul. You can find both [SCC files here](../resources/ha/scc).

The Red Hat OpenShift Container Platform (OCP) provides pod security policies using SecurityContextConstraints (SCC) resources rather than the PodSecurityPolicies (PSP) like all other Kubernetes platforms. SCCs control the actions that a pod can perform and what it has the ability to access.

Create your namespace and deploy Consul :

```shell
oc create ns vault
```

```shell
helm upgrade -i consul-ha --namespace vault consul/ --set ui.enabled=true
```

Your pods won't deploy as `DaemonSet` and `StatefulSet` are on error :

```console
[root@workstation ~ ]$ oc describe daemonset.apps/consul-ha-consul
[...]
Events:
  Type     Reason        Age                 From                  Message
  ----     ------        ----                ----                  -------
  Warning  FailedCreate  22s (x14 over 63s)  daemonset-controller  Error creating: pods "consul-ha-consul-" is forbidden: unable to validate against any security context constraint: [spec.containers[0].securityContext.containers[0].hostPort: Invalid value: 8500: Host ports are not allowed to be used spec.containers[0].securityContext.containers[0].hostPort: Invalid value: 8502: Host ports are not allowed to be used]
```

```console
[root@workstation ~ ]$ oc describe statefulset.apps/consul-ha-consul-server
[...]
Events:
  Type     Reason        Age                 From                    Message
  ----     ------        ----                ----                    -------
  Warning  FailedCreate  10s (x21 over 23m)  statefulset-controller  create Pod consul-ha-consul-server-0 in StatefulSet consul-ha-consul-server failed error: pods "consul-ha-consul-server-0" is forbidden: unable to validate against any security context constraint: [fsGroup: Invalid value: []int64{1000}: 1000 is not an allowed group]
```

You need to apply SCC :

```shell
oc apply -f consul-server-scc.yaml
oc apply -f consul-client-scc.yaml
```

Then apply SCC to Service Accounts :

```console
[root@workstation ~ ]$ oc adm policy add-scc-to-user consul-client -z consul-ha-consul-client
securitycontextconstraints.security.openshift.io/consul-client added to: ["system:serviceaccount:vault:consul-ha-consul-client"]
[root@workstation ~ ]$ oc adm policy add-scc-to-user consul-server -z consul-ha-consul-server
securitycontextconstraints.security.openshift.io/consul-server added to: ["system:serviceaccount:vault:consul-ha-consul-server"]
```

Then your pod should deploy properly after that :

```console
[root@workstation ~ ]$ oc get pods
NAME                        READY   STATUS    RESTARTS   AGE
consul-ha-consul-bq7hx      1/1     Running   0          8m14s
consul-ha-consul-c8n8j      1/1     Running   0          8m14s
consul-ha-consul-server-0   1/1     Running   0          8m14s
consul-ha-consul-server-1   1/1     Running   0          8m14s
consul-ha-consul-server-2   1/1     Running   0          8m14s
consul-ha-consul-z2rcn      1/1     Running   0          8m14s
```

### 3.2 Install Vault HA

You can download official Hashicorp helm chart Vault from `https://github.com/hashicorp/vault-helm`

```shell
helm repo add hashicorp https://helm.releases.hashicorp.com
helm repo update
helm fetch --untar hashicorp/vault
```

Install Vault using these parameters :

```console
helm upgrade -i vault-ha --namespace vault vault/ --set server.ha.enabled=true --set ui.enabled=true --set global.openshift=true
```


### Interesting links :

- https://www.ibm.com/support/knowledgecenter/SSSHTQ/omnibus/helms/all_helms/wip/reference/hlm_sec_context_constraints.html
- https://github.com/hashicorp/consul-helm/issues/283
- https://www.vaultproject.io/docs/platform/k8s/helm/run
- https://www.vaultproject.io/docs/concepts/ha
- https://www.vaultproject.io/docs/platform/k8s/helm/examples/standalone-tls
