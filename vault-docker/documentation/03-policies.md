[Retour menu principal](../README.md)

# 3. Policies configuration
## General

Official documentation :
- https://www.vaultproject.io/docs/concepts/policies
- https://learn.hashicorp.com/tutorials/vault/policies

Everything in Vault is path based, and policies are no exception. Policies provide a declarative way to grant or forbid access to certain paths and operations in Vault. This section discusses policy workflows and syntaxes.

Each path must define one or more capabilities which provide fine-grained control over permitted (or denied) operations. The list of capabilities are:

- `create` (POST/PUT) - Allows creating data at the given path. Very few parts of Vault distinguish between create and update, so most operations require both create and update capabilities. Parts of Vault that provide such a distinction are noted in documentation.

- `read` (GET) - Allows reading the data at the given path.

- `update` (POST/PUT) - Allows changing the data at the given path. In most parts of Vault, this implicitly includes the ability to create the initial value at the path.

- `delete` (DELETE) - Allows deleting the data at the given path.

- `list` (LIST) - Allows listing values at the given path. Note that the keys returned by a list operation are not filtered by policies. Do not encode sensitive information in key names. Not all backends support listing.

In addition to the standard set, there are some capabilities that do not map to HTTP verbs.

- `sudo` - Allows access to paths that are root-protected. Tokens are not permitted to interact with these paths unless they have the sudo capability (in addition to the other necessary capabilities for performing an operation against that path, such as read or delete). For example, modifying the audit log backends requires a token with sudo privileges.

- `deny` - Disallows access. This always takes precedence regardless of any other defined capabilities, including sudo.

You can list existing policies with these commands : 

```shell
vault policy list
vault read sys/policy
```

and read a specific policy with these commands :
```shell
vault policy read <policy-name>
vault read sys/policy/<policy-name>
```

Create a new policy :
```shell
vault policy write <policy-name> <policy-file.hcl>
```

To update an existing policy with new values :
```shell
vault write sys/policy/<existing-policy-name> policy=@"<updated-policy-file.hcl>"
```

If you need to delete a policy :
```shell
vault delete sys/policy/<policy-name>
```

## Creating and applying policies

Few policies are available here [policies](../resources), there is an **[admin](../resources/admin-policy.hcl)** policy allowing everything on Vault, this is the superadmin permission. **[Privileged](../resources/privileged-policy.hcl)** policy to allow slighlty restricted access but with still many permissions and finally, **[readonly](../resources/readOnly-policy.hcl)** policy to allow only secret reading to service accounts for example.

You can copy these policies under the `policies` directory mapped from your host to your container (in the docker-compose file) and log in your Vault container to apply policy :

```console
/ # vault policy write RO-secret /vault/policies/readonly-policy.hcl
Success! Uploaded policy: ro-secret
```

If you need to update this policy by changing some permissions :

```console
/ # vault write sys/policy/RO-secret policy=@"/vault/policies/readonly-policy.hcl"
Success! Data written to: sys/policy/RO-secret
```

Update is applied instantly.

Check your existing policies :

```console
/ # vault read sys/policy
Key         Value
---         -----
keys        [admins default ro-secret root]
policies    [admins default ro-secret root]
```

Apply policies to LDAP groups :

```console
/ # vault write auth/ldap/groups/vault_cmpcore_dev policies=ro-secret
Success! Data written to: auth/ldap/groups/vault_cmpcore_dev
/ # vault write auth/ldap/groups/vault_awx_dev policies=ro-secret
Success! Data written to: auth/ldap/groups/vault_awx_dev
```

List groups in Vault with a policy mapping :

```console
/ # vault list auth/ldap/groups
Keys
----
vault_admins
vault_awx_dev
vault_cmpcore_dev
```

To check the policies applied to a group :

```console
/ # vault read auth/ldap/groups/vault_cmpcore_dev
Key         Value
---         -----
policies    [ro-secret]
/ # vault read auth/ldap/groups/vault_awx_dev
Key         Value
---         -----
policies    [ro-secret]
```

## Secret engine access

If you want to give permissions upon a secret engine :

```hcl
path "kv-test/*"
{
  capabilities = ["read", "list", "create", "update", "delete"]
}
```

If you need to restrict access to some secret engines, you can use this syntaxe :

```hcl
path "kv-test/*"
{
  capabilities = ["deny"]
}
```

This denies access to all datas in secret engine `kv-test`. 

