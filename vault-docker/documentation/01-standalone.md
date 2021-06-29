[Retour menu principal](../README.md)

## 1. Standalone install 

### 1.1 Docker-compose file

To install Vault it's recommended to work with `docker-compose.yaml` file.

Vault should be run in HTTPS mode so you need first to create certificates (you can create self-signed). Once you have your `server.crt` and `server.key` file, store both files in a `certs` directory like shown below :

```
certs/
├── server.crt
└── server.key
```

You also need to convert both certificate and key to `PEM` format.

Certificate:
```
openssl x509 -in server.crt -out vault.pem -outform PEM
```

Key:
```
openssl rsa -in server.key -text > private.pem
```

Since this is a self signed certificate, we will use our certificate as a CA certificate. Copy `server.pem` to `CA.Pem`.
You should have these files :

```
certs/
├── CA.pem
├── private.pem
├── server.crt
├── server.key
└── vault.pem
```

After this step, you need to edit the Vault configuration through `vault.json` file. Here is an example :

```json
{
  "backend": {
    "file": {
      "path": "/vault/data"
    }
  },
  "listener": {
    "tcp":{
      "address": "0.0.0.0:8200",
      "tls_cert_file": "/etc/certs/vault.pem",
      "tls_key_file": "/etc/certs/private.pem",
      "tls_client_ca_file": "/etc/certs/CA.pem"
    }
  },
  "ui": true,
  "default_lease_ttl": "168h",
  "max_lease_ttl": "720h",
  "disable_mlock": false,
  "log_level": "debug"
}
```

Create a `volumes` directory and put your vault config file in a `config` subfolder :

```
volumes/
└── config
    └── vault.json
```

Now you can edit you `docker-compose.yaml` file and make sure that you are mapping your different host directories with your container like shown below : 

```yaml
version: '3.6'
services:
  vault:
    image: vault:1.5.0
    container_name: vault
    hostname: vault-argo.devibm.local
    ports:
      - "8200:8200"
    restart: always
    environment:
    - VAULT_CACERT=/etc/certs/CA.pem
    - VAULT_CLIENT_CERT=/etc/certs/vault.pem
    - VAULT_CLIENT_KEY=/etc/certs/private.pem
    - VAULT_ADDR=https://vault-argo.devibm.local:8200
    volumes:
      - ./volumes/logs:/vault/logs:rw
      - ./volumes/data:/vault/data:rw
      - ./volumes/policies:/vault/policies:rw
      - ./volumes/config:/vault/config:rw
      - ./certs/CA.pem:/etc/certs/CA.pem
      - ./certs/vault.pem:/etc/certs/vault.pem
      - ./certs/private.pem:/etc/certs/private.pem
    cap_add:
      - IPC_LOCK
    entrypoint: vault server -config=/vault/config/vault.json
```

Now you juste need to run your vault instance :

```console
[root@vault-container ~ ]$ docker-compose up -d
Creating network "vault_default" with the default driver
Creating vault ... done
```

```console
[root@vault-container ~ ]$ docker ps
CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS              PORTS                    NAMES
d78c32178577        vault:1.5.0         "vault server -confi…"   6 minutes ago       Up 6 minutes        0.0.0.0:8200->8200/tcp   vault
```

### 1.2 Initialize and unseal vault

Vault need to be initated and unsealed to be working properly. You can do it throught the web UI, but we will scribe the CLI procedure here. Docker exec into your container :

```
docker exec -it vault sh
```

Then initiate Vault :

```
vault operator init --tls-skip-verify -key-shares=1 -key-threshold=1
```

You should be prompted with `Root token` and `Useal Key` that you **NEED** to keep somewhere safe :

```
Unseal Key 1: n3WaN5Q9Blx8sqJ94Al3f4/dcmo3/tnJXdl/i1dhGvg=

Initial Root Token: s.0MsoP8bdtwoqk5HJcpnKN5Az

Vault initialized with 1 key shares and a key threshold of 1. Please securely
distribute the key shares printed above. When the Vault is re-sealed,
restarted, or stopped, you must supply at least 1 of these keys to unseal it
before it can start servicing requests.

Vault does not store the generated master key. Without at least 1 key to
reconstruct the master key, Vault will remain permanently sealed!

It is possible to generate new unseal keys, provided you have a quorum of
existing unseal keys shares. See "vault operator rekey" for more information.
```

Now just unseal your Vault instance with the unseal key :

```console
[root@vault-container ~ ]$ vault operator unseal --tls-skip-verify n3WaN5Q9Blx8sqJ94Al3f4/dcmo3/tnJXdl/i1dhGvg=
Key             Value
---             -----
Seal Type       shamir
Initialized     true
Sealed          false
Total Shares    1
Threshold       1
Version         1.5.0
Cluster Name    vault-cluster-aaa7b62d
Cluster ID      e2302892-6507-ccad-6f37-fa06282b0f2a
HA Enabled      false
```

**Initialized** is set to `true` and **Sealed** is set to `false` which confirms that your Vault instance is installed properly.












---------------------------------------------------------------------------------------------------------------------------------

[Retour menu principal](../README.md)

[Suivant](02-update-vault-image.md)

