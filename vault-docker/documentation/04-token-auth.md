[Retour menu principal](../README.md)

# 4. Token authentication
## General

Useful links : 

- https://learn.hashicorp.com/tutorials/vault/tokens?in=vault/auth-methods
- https://www.vaultproject.io/docs/commands/token/create.html

Token is a core authentication method in Vault with some default settings. 

To check the list of enabled authentication, use this command :

```
vault auth list -detailed
```

Then you can check for each auth method, its default values :

```console
/ # vault read sys/mounts/auth/ldap/tune
Key                  Value
---                  -----
default_lease_ttl    168h
description          n/a
force_no_cache       false
max_lease_ttl        720h
token_type           default-service

/ # vault read sys/mounts/auth/token/tune
Key                  Value
---                  -----
default_lease_ttl    720h
description          token based credentials
force_no_cache       false
max_lease_ttl        720h
token_type           default-service
```

If you want to change default TTL and max TTL for auth method, you can do it using this command :

```
vault write sys/mounts/auth/token/tune default_lease_ttl=720h max_lease_ttl=8760h
```

and verify your changes with command :

```
vault read sys/mounts/auth/token/tune
```

## Creation

First create a token role named as you want, for example "orchestrator" and assign it with a policy and maximum period :

```console
/ # vault write auth/token/roles/orchestrator allowed_policies="readonly-secret" period="8760h"
Success! Data written to: auth/token/roles/orchestrator
```

you can list your roles :

```console
/ # vault list auth/token/roles
Keys
----
orchestrator
```

and read a specific one : 

```console
/ # vault read auth/token/roles/orchestrator
Key                       Value
---                       -----
allowed_entity_aliases    <nil>
allowed_policies          [readonly-secret]
disallowed_policies       []
explicit_max_ttl          0s
name                      orchestrator
orphan                    false
path_suffix               n/a
period                    8760h
renewable                 true
token_explicit_max_ttl    0s
token_period              8760h
token_type                default-service
```

Then create your token :

```console
/ # vault token create -role=orchestrator
Key                  Value
---                  -----
token                s.ZhdV1MJZYenDUYhVwwz5EyPW
token_accessor       myY7BVkyKFm1tQXwznOahfbf
token_duration       8760h
token_renewable      true
token_policies       ["default" "readonly-secret"]
identity_policies    []
policies             ["default" "readonly-secret"]
```

you can now authenticate with token `s.ZhdV1MJZYenDUYhVwwz5EyPW`

If you prefer to have a customized token value, you can add the flag `-id` to your command and give a value to your token :

```
vault token create -role=orchestrator -id <token-value>
```



