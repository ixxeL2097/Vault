[Retour menu principal](../README.md)

## 3. Configure LDAPS authentication

Configuring LDAPS in Vault can be done from Vault CLI or Web UI. 

First ensure that you have the Active Directory certificate available. You can create a `Secret` for this certificate and mount it into your pod :

```console
[root@VLPCLA01 vault-install]# oc create secret generic ad-prodibm-cert --from-file=ad-cert.pem=./ad-cert.pem -n vault
secret/ad-prodibm-cert  created
```

Mount the secret into your pod by editing `Statefulset/Deployment` 

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
            - secret:
                name: ad-prodibm-cert
```

You can now `rsh` into your vault pod and execute commands to configure LDAPS. (Before executing command inside Vault pod, first export your Vault Root token)

```console
/vault # vault auth enable --tls-skip-verify -path=ldap_prodibm/ ldap
Success! Enabled ldap auth method at: ldap_prodibm/
```

Now configure your LDAPS access. You need a service account (bind dn) to request your Active Directory. In this case we use service account `vault_ldap` :

```bash
vault write --tls-skip-verify auth/ldap_prodibm/config \
url="ldaps://frnsp0000019.prodibm.wcorp.carrefour.com:636" \
certificate=@/vault/certs/ad-cert.pem \
userattr="sAMAccountName" \
userdn="dc=prodibm,dc=wcorp,dc=carrefour,dc=com" \
groupdn="dc=prodibm,dc=wcorp,dc=carrefour,dc=com" \
binddn="cn=vault_ldap,cn=Users,dc=prodibm,dc=wcorp,dc=carrefour,dc=com" \
bindpass='password' \
insecure_tls="false" \
case_sensitive_names="false" \
starttls="true" \
groupfilter="(&(objectClass=group)(member:1.2.840.113556.1.4.1941:={{.UserDN}}))"
```

This example configure LDAPS access on `sAMAccountName` with appropriate certificate from the Active Directory server and Nested group research activated.

check your configuration with following command :

```shell
vault read --tls-skip-verify /auth/ldap_prodibm/config
```

and then test to authenticate with a user account :

```shell
vault login --tls-skip-verify -method=ldap -path=ldap_prodibm username=fr106631
```

You should be able to login properly. Now that you have configured LDAPS access properly, you need to map some groups to your Vault with appropriate policies. Please refer to the policies chapter to get more information on policies. We assume that you have created following policies :

```console
/vault # vault policy list --tls-skip-verify
admin-policy
default
dev-policy
privileged-policy
readonly-policy
root
```

Create a `vault_admins` group in your Active Directory server, then map it to your Vault server with the `admin-policy` policy :

```shell
vault write --tls-skip-verify auth/ldap_prodibm/groups/vault_admins policies=admin-policy
```

and check it :

```shell
/ $ vault list --tls-skip-verify auth/ldap_prodibm/groups
Keys
----
vault_admins
```

You can do it several times to map Active Directory groups to your Vault instance.


