# Manage auth methods broadly across Vault
path "auth/*"
{
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

# Create, update, and delete auth methods
path "sys/auth/*"
{
  capabilities = ["create", "update", "delete", "sudo"]
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

# Create and manage ACL policies
path "sys/policies/acl/*"
{
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
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
