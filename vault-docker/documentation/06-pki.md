[Retour menu principal](../README.md)

# 6. PKI

## 6.1 Root CA

First, enable the pki secrets engine at the pki_root path then tune the pki secrets engine to issue certificates with a maximum time-to-live (TTL) of 87600 hours.

```console
/ # vault secrets enable -path=pki_root pki
Success! Enabled the pki secrets engine at: pki_root/
/ # vault secrets tune -max-lease-ttl=87600h pki_root
Success! Tuned the secrets engine at: pki_root/
```

Note that individual roles can restrict this value to be shorter on a per-certificate basis. This just configures the global maximum for this secrets engine.

Generate the root certificate and save the certificate

```console
/ # vault write -field=certificate pki_root/root/generate/internal common_name="test.local" ttl=87600h > ROOT_CA_cert.crt
```

This generates a new self-signed CA certificate and private key. Vault will automatically revoke the generated root at the end of its lease period (TTL); the CA certificate will sign its own Certificate Revocation List (CRL).

The returned certificate is purely informative. The private key is safely stored internally in Vault.

Update the CRL location and issuing certificates. These values can be updated in the future.

```console
/ # vault write pki_root/config/urls issuing_certificates="https://vault.test.local:8200/v1/pki/ca" crl_distribution_points="https://vault.test.local:8200/v1/pki/crl"
Success! Data written to: pki_root/config/urls
```

## 6.2 Intermediate CA

Now, you are going to create an intermediate CA using the root CA you regenerated in the previous step

Then create and configure an intermediate pki :

```console
/ # vault secrets enable -path=pki_int pki
Success! Enabled the pki secrets engine at: pki_int/
/ # vault secrets tune -max-lease-ttl=43800h pki_int
Success! Tuned the secrets engine at: pki_int/
```

Execute the following command to generate an intermediate and save the CSR

```console
/ # vault write pki_int/intermediate/generate/internal common_name="test.local Intermediate Authority" > INTER_pki.csr
```

Sign the intermediate certificate with the root certificate and save the generated certificate

```console
/ # vault write pki_root/root/sign-intermediate csr=@INTER_pki.csr format=pem_bundle ttl="43800h" > INTER_pki.pem
```

Once the CSR is signed and the root CA returns a certificate, it can be imported back into Vault.

```console
/ # vault write pki_int/intermediate/set-signed certificate=@INTER_pki.pem
Success! Data written to: pki_int/intermediate/set-signed
```

## 6.3 Create a role

Use the web UI to create your role 

## 6.4 Request certificates

Use the web UI to create your role

## 6.5 Revoke certificates

You can use this command to revoke certificates :

```shell
vault write pki_int/revoke serial_number=<serial_number>
```

To find the serial number of a certificate, you can use this command :

```shell
openssl x509 -noout -serial -in server.pem |  sed 's/.*=//g;s/../&:/g;s/:$//'
```

## 6.6 Remove expired certificates

Keep the storage backend and CRL by periodically removing certificates that have expired and are past a certain buffer period beyond their expiration time.

```shell
vault write pki_int/tidy tidy_cert_store=true tidy_revoked_certs=true
```

## 6.7 Replace Vault own certificate 

Once you have properly deployed pki_int and pki_root, you can issue a certificate for your vault server from the pki_int.
Generate a new certificate from a role in the web UI and copy the `Certificate` in a `vault.pem` file. Copy the `Key` in a `private.pem` file.


- https://www.hashicorp.com/blog/certificate-management-with-vault
- https://www.vaultproject.io/api-docs/secret/pki
- https://www.vaultproject.io/docs/secrets/pki
- https://learn.hashicorp.com/tutorials/vault/pki-engine


