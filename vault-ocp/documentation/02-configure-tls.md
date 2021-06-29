[Retour menu principal](../README.md)

## 2. Configure Vault with TLS HTTPS endpoint

To configure HTTPS termination on Vault you can do it several ways with Openshift. The method we gonna describe here is `Passthrough` route with our own certificate.

First we need to create a **Root PKI** and an **intermediate PKI** to generate certificates. We recommand to do it with web GUI but you can also do it with Vault CLI as well. Consult associated chapter to create Root pki, Int pki and Vault certificate.

To configure Vault with HTTPS endpoint, you will need :

- Vault cert (.pem)
- Vault private key (.pem)
- CA cert (.pem)

Once you have all these files, you can create a secret from Vault cert and Vault private key in your namespace where Vault is installed :

```console
[root@VLPCLA01 vault-install]# oc create secret tls vault-cert --cert=/home/ibmroot/vault-install/server.pem --key=/home/ibmroot/vault-install/private.pem -n vault
secret/vault-cert created
```

Then create a secret for the CA certificate as well :

```console
[root@VLPCLA01 vault-install]# oc create secret generic pki-int-cert --from-file=CA.pem=/home/ibmroot/vault-install/CA.pem -n vault
secret/pki-int-cert created
```

Kubernetes will encode both certificate and private key in the `Secret` resource. You can now mount the Vault secret and CA secret to your Vault pod by editing `Statefulset/Deployment`.

```shell
oc edit statefulset.apps/vault
```

Modify `volumeMounts` section to add a path for your certificates :

```yaml
volumeMounts:
        - mountPath: /vault/data
          name: data
        - mountPath: /vault/config
          name: config
        - mountPath: /home/vault
          name: home
        - mountPath: /vault/certs
          name: certs
          readOnly: true
```

Then add a first secret `vault-cert` :

```yaml
volumes:
      - configMap:
          defaultMode: 420
          name: vault-config
        name: config
      - emptyDir: {}
        name: home
      - name: certs
        secret:
          defaultMode: 420
          secretName: vault-cert
```

To add both secrets to the same path in your container, use this syntaxe :

```yaml
        volumes:
        - configMap:
            defaultMode: 420
            name: vault-config
          name: config
        - emptyDir: {}
          name: home
        - name: certs
          projected:
            defaultMode: 420
            sources:
            - secret:
                name: pki-int-cert
            - secret:
                name: vault-cert
```

you also need to specify Vault that your are using HTTPS host now. Edit the `Statefulset/Deployment` and modify the container env variable `VAULT_ADDR` to specify **https** instead of **http**:

```yaml
        - name: VAULT_ADDR
          value: https://127.0.0.1:8200
```

Now you can check that your pod has access to your different secrets by rsh into it (you might need to kill your pod to take into account your changes)

```console
[root@VLPCLA01 ~]# oc rsh vault-0
/ $ ls /vault/certs
CA.pem     tls.crt      tls.key
```

Now that certificates are mounted to your pod, your can change the Vault configuration by editing Vault `configMap`

```shell
oc edit cm vault-config
```

You need to modify the **data** part of the `configMap` as following:

```yaml
data:
  extraconfig-from-values.hcl: |-
    disable_mlock = true
    ui = true

    listener "tcp" {
      tls_cert_file = "/vault/certs/tls.crt"
      tls_key_file = "/vault/certs/tls.key"
      tls_client_ca_file = "/vault/certs/CA.pem"
      address = "[::]:8200"
      cluster_address = "[::]:8201"
    }
    storage "file" {
      path = "/vault/data"
    }
```

Once again kill your pod to take into account changes. Your Vault instance should now serve UI on HTTPS. You now have to create a route to access your server. In this case, we will use passthrough route. 

Create the route :

```console
[root@VLPCLA01 vault-install]# oc create route passthrough vault-ui-tls --service vault-ui --hostname vault-argo.prodibm.wcorp.carrefour.com
route.route.openshift.io/vault-ui-tls created
[root@VLPCLA01 vault-install]# oc get route
NAME           HOST/PORT                                PATH   SERVICES   PORT   TERMINATION   WILDCARD
vault-ui-tls   vault-argo.prodibm.wcorp.carrefour.com          vault-ui   http   passthrough   None
```

You can now access your Vault instance on the URL described by the route (Don't forget to update your DNS).
