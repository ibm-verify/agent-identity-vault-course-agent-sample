# Reference least-privilege starting point for the agent synchronization adapter.
# Review/narrow for your Vault namespace and production operating model.
path "identity/entity" {
  capabilities = ["create", "update"]
}
path "identity/entity/name/*" {
  capabilities = ["create", "read", "update", "delete"]
}
path "identity/entity/id/*" {
  capabilities = ["read", "update", "delete"]
}
path "identity/entity-alias" {
  capabilities = ["create", "update"]
}
path "identity/entity-alias/id/*" {
  capabilities = ["read", "update", "delete"]
}
path "identity/lookup/entity" {
  capabilities = ["update"]
}
path "agent-registry/register" {
  capabilities = ["create", "update"]
}
path "agent-registry/registration/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}
# Optional read so the adapter can validate the configured OAuth Resource Server profile.
path "sys/config/oauth-resource-server/*" {
  capabilities = ["read"]
}
