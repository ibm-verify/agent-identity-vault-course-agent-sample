# 0. Execution Checklist — One Continuous Path

Use this page while implementing. Detailed instructions are in the numbered chapters.

## Phase 0 — Confirm the environment

```text
[ ] Vault reachable and unsealed
[ ] Vault Agent Registry API available
[ ] Vault OAuth Resource Server capability available
[ ] KV v2 permitted (required for API-key use case)
```

Run:

```bash
bash vault/scripts/00_check_compatibility.sh
```

## Phase 1 — Prepare Vault foundation

```text
[ ] Activate OAuth Resource Server
[ ] Create course-verify profile
[ ] issuer = IBM Verify issuer
[ ] JWKS configured
[ ] audience = vault-course-tools
[ ] RAR required
[ ] Record config_id/mount accessor
[ ] Create course-tool-subject policy
[ ] Create course-tool-ceiling policy
[ ] Create restricted VAULT_SYNC_TOKEN
```

## Phase 2 — Create Course Assistant in IBM Verify

```text
[ ] Create Course Assistant Agent
[ ] Status ACTIVE
[ ] Create Course Assistant Runtime OIDC client
[ ] Grant = Client Credentials
[ ] Access token = JWT
[ ] Associate runtime OIDC client with Agent
[ ] Obtain/decode actor token
[ ] Record actor token sub/client_id
```

## Phase 3 — Synchronize Agent to Vault

Choose Antenna or custom adapter.

```text
[ ] Vault Identity entity exists
[ ] OAuth alias resolves actor runtime identity
[ ] Agent Registry registration exists
[ ] entity_id is Vault-generated entity ID
[ ] ceiling_policies contains course-tool-ceiling
[ ] optional_authorization_details=false
```

## Phase 4 — Validate the new license and store the API key

Do this before opening IBM Verify Guide 8.

```text
[ ] New non-PKI Vault license is active
[ ] Compatibility gate passes, including temporary KV v2 mount
[ ] course-tools KV v2 enabled
[ ] api_key stored at course-tools/premium-enrollment
[ ] Administrator read succeeds
```

## Phase 5 — Configure human + OBO in IBM Verify

```text
[ ] Course Portal OIDC app: Authorization Code + PKCE + JWT
[ ] may_act configured for Course Assistant actor
[ ] vault:path_access ADT created
[ ] Course Vault Token Exchange OIDC app created
[ ] Grant = Token Exchange
[ ] Subject token = Access Token
[ ] Actor token = Access Token
[ ] Require actor token = ON
[ ] Access token format = JWT
[ ] Audience = vault-course-tools
[ ] Restrict auth details = vault:path_access
```

## Phase 6 — Smoke test before UI

```text
[ ] Actor token works
[ ] Subject token works and may_act is correct
[ ] Human Vault entity/alias created
[ ] Token exchange works
[ ] Delegated JWT aud includes vault-course-tools
[ ] Delegated JWT carries exact vault:path_access
[ ] Vault secret read succeeds using delegated JWT directly
```

## Phase 7 — Run application

```text
[ ] npm ci
[ ] npm test
[ ] npm start
[ ] Standard course succeeds
[ ] Premium course succeeds
```

## Phase 8 — Prove controls

```text
[ ] Remove/suspend Agent Registry registration → Vault denies premium secret
[ ] Restore Agent → premium succeeds
[ ] Change only Vault API key → Vault read succeeds, tool returns 403
[ ] Restore correct API key → premium succeeds
```
