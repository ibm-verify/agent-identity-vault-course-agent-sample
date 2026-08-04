# Values Worksheet

Fill this file while following the cookbook. Keep real secrets out of Git.

```bash
# IBM Verify
VERIFY_TENANT_HOST=
VERIFY_ISSUER=https://<tenant>/oauth2
VERIFY_JWKS_URI=https://<tenant>/oauth2/jwks

# Human / subject application
SUBJECT_CLIENT_ID=
SUBJECT_CLIENT_SECRET=
SUBJECT_REDIRECT_URI=http://localhost:4000/callback
SUBJECT_TOKEN_SUB=

# Course Assistant agent and actor application
VERIFY_AGENT_ID=
ACTOR_CLIENT_ID=
ACTOR_CLIENT_SECRET=
ACTOR_TOKEN_SUB=

# Token Exchange OIDC application
TOKEN_EXCHANGE_CLIENT_ID=
TOKEN_EXCHANGE_CLIENT_SECRET=
VAULT_AUDIENCE=vault-course-tools

# Vault
VAULT_ADDR=http://127.0.0.1:8200
VAULT_NAMESPACE=
VAULT_OAUTH_PROFILE=course-verify
VAULT_OAUTH_CONFIG_ID=
VAULT_OAUTH_MOUNT_ACCESSOR=
VAULT_AGENT_ENTITY_ID=
VAULT_AGENT_REGISTRATION_ID=
VAULT_SUBJECT_ENTITY_ID=

# Secret / tool
VAULT_KV_MOUNT=course-tools
VAULT_SECRET_API_PATH=course-tools/data/premium-enrollment
VAULT_SECRET_FIELD=api_key
PREMIUM_API_EXPECTED_KEY=course-premium-demo-key-2026

# Antenna sync only
VERIFY_SYNC_CLIENT_ID=
VERIFY_SYNC_CLIENT_SECRET=
VAULT_SYNC_TOKEN=
NGROK_URL=
```

## Identity cross-check

```text
IBM Verify Agent ID              = __________________________
Actor OAuth client_id            = __________________________
Actor access-token sub           = __________________________
Vault OAuth alias name           = __________________________
Vault OAuth alias external_id    = __________________________
Vault OAuth alias issuer         = __________________________
Vault OAuth alias id             = __________________________
Vault canonical entity_id        = __________________________
Vault Agent Registry record id   = __________________________
```

The alias name must match the actor identity expected by the Vault OAuth resource-server binding. Validate the actor token before finalizing the sync mapping.
