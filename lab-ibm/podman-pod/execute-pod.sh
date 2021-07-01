#!/bin/bash

# Set colors variables
RED="\033[1;31m"
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
BLUE="\033[1;34m"
PURPLE="\033[1;35m"
CYAN="\033[1;36m"
BLANK="\033[0m"

REGISTRY="jfrog-argo.devibm.local:3443"
PODMAN_YAML="/home/fred/Documents/TEST/podman/vault/yaml/podman-vault-pod.yaml"

echo -e "${YELLOW}[ PODMAN LOGIN ] > Login to registry $REGISTRY ${BLANK}"
podman login $REGISTRY --username admin --tls-verify=false

echo -e "${YELLOW}[ PODMAN POD RUN ] > Running podman pod${BLANK}"
podman play kube $PODMAN_YAML