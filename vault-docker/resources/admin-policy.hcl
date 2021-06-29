# Grant maximum privileges upon all Vault resources
path "*" {
    capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}