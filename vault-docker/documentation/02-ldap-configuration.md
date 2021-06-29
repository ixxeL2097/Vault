[Retour menu principal](../README.md)

# 2. LDAP configuration

Official documentation :
- https://www.vaultproject.io/docs/auth/ldap

To configure Vault for LDAP authentication, you need to ensure that environment variables are set when TLS is activated on Vault :

- `VAULT_CACERT` --> Point to your CA certificate in PEM format
- `VAULT_CLIENT_CERT` --> Point to your Vault certificate in PEM format
- `VAULT_CLIENT_KEY` --> Point to your Vault private key in PEM format
- `VAULT_ADDR` --> Your Vault FQDN corresponding to your certificate
- `VAULT_TOKEN` --> Use root token for configuration 

If not set in your `docker-compose.yaml` file, you need to export these variables :

```shell
export VAULT_ADDR=https://vault.example.com:8200
export VAULT_TOKEN=s.om4w0iZmqwVYgVSxKZcB4IUE
```

`VAULT_TOKEN` is only needed to be set for configuration, you can unset this variable after configuring your vault instance.

**/!\ WARNING !** : If you are working with container, don't forget you need a DNS or `/etc/hosts` configured properly to point to your FQDN and LDAP server.

Once variables set, you can activate LDAP authentication. You can do it though WEB GUI or in CLI :

```console
/vault # vault auth enable ldap
Success! Enabled ldap auth method at: ldap/
```

Once LDAP enabled, you need to configure it. There are many options to configure your LDAP but here is  simple example :

```shell
vault write auth/ldap/config \
url="ldap://ad-dev.devibm.local:389" \
userattr="sAMAccountName" \
userdn="dc=devibm,dc=local" \
groupdn="dc=devibm,dc=local" \
binddn="cn=vault_ldap,cn=Users,dc=devibm,dc=local" \
bindpass='Passw0rd#' \
insecure_tls="true" \
case_sensitive_names="false" \
starttls="false"
```

You can change `userattr` parameter to be either `sAMAccountName`, `userPrincipalName`, `guid` or `cn` (default is cn) according to your needs for logon.

Set your configuration in Vault :

```console
/ # vault write auth/ldap/config \
> url="ldap://ad-dev.devibm.local:389" \
> userattr="sAMAccountName" \
> userdn="dc=devibm,dc=local" \
> groupdn="dc=devibm,dc=local" \
> binddn="cn=vault_ldap,cn=Users,dc=devibm,dc=local" \
> bindpass='Passw0rd#' \
> insecure_tls="true" \
> case_sensitive_names="false" \
> starttls="false"
Success! Data written to: auth/ldap/config
```

By default, this configuration does not accept nested group synchronisation. The default value of `groupfilter` attribute is `(|(memberUid={{.Username}})(member={{.UserDN}})(uniqueMember={{.UserDN}}))` (not needed here). So if you want to add nested group synchronisation, you need to add the following line to then ldap conf :

```
groupfilter="(&(objectClass=group)(member:1.2.840.113556.1.4.1941:={{.UserDN}}))"
```

to check the config execute following command : 

```
vault read /auth/ldap/config
```

You can now test your login configuration :

```console
/ # vault login -method=ldap username=fr106631
Password (will be hidden): 
Success! You are now authenticated. The token information displayed below
is already stored in the token helper. You do NOT need to run "vault login"
again. Future Vault requests will automatically use this token.

Key                    Value
---                    -----
token                  s.V9XKeSMcSCGITulko2WHaLKB
token_accessor         pmQBZo8WkY58JgYkXuzrsIzJ
token_duration         168h
token_renewable        true
token_policies         ["default"]
identity_policies      []
policies               ["default"]
token_meta_username    fr106631
```

You can also check auth list :

```console
/ # vault auth list
Path      Type     Accessor               Description
----      ----     --------               -----------
ldap/     ldap     auth_ldap_8f1d32dd     n/a
token/    token    auth_token_2b607826    token based credentials
```

Authentication is working but you need to map your LDAP groups to Vault policy to grant or deny access to your Vault resources.
Here is how to create a mapping from an LDAP group to a Vault policy :

```
vault write auth/ldap/groups/vault_admins policies=admins
```

List groups in Vault with a policy mapping :

```
vault list auth/ldap/groups
```

Check the `03-Policies` chapter to configure policies [03-Policies chapter](03-policies.md)
