# List auth methods
path "auth/*"
{
  capabilities = ["read", "list"]
}

# List auth methods
path "sys/auth"
{
  capabilities = ["read", "list"]
}

# List existing policies
path "sys/policies/acl"
{
  capabilities = ["read", "list"]
}

# View policies permissions
path "sys/policies/acl/*"
{
  capabilities = ["read", "list"]
}

# Manage secrets engines
path "sys/mounts/*"
{
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

# List existing secrets engines.
path "sys/mounts"
{
  capabilities = ["read", "list"]
}

# Read health checks
path "sys/health"
{
  capabilities = ["read", "sudo"]
}

# Full access UI metadata
path "+/metadata/*"
{
  capabilities = ["read", "list"]
}

# Full access UI data
path "+/data/*"
{
  capabilities = ["read", "list"]
}
