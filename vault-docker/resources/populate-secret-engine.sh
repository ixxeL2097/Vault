#!/bin/bash

token=s.bXW9h6Nc93dMkp0sxd9baBhP
engine=adc4fr

curl -k \
    --header "X-Vault-Token: $token" \
    --request POST \
    --data '{"data": {"join_domain_password": "Passw0rd","join_domain_user": "ad-ansible-tower"}}' \
    https://127.0.0.1:8200/v1/kv-test/data/$engine