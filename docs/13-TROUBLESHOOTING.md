# 13. Troubleshooting

For the exact Mac, Vault CLI, license, OAuth mount-accessor, template-rendering, Colima, and Antenna receiver issues validated while building this package, start with [13A-VALIDATED-SETUP-TROUBLESHOOTING.md](13A-VALIDATED-SETUP-TROUBLESHOOTING.md).

Troubleshoot in the same order as the architecture. Do not start with the Course Portal if an earlier checkpoint is failing.

## 13.1 Vault compatibility

### KV enable fails

Likely causes:

- PKI-only licensed cluster.
- Token lacks mount-management permission.
- Namespace mismatch.

If the cluster is PKI-only, this API-key use case cannot use KV on that cluster.

## 13.2 Agent synchronization

### Vault entity exists but Agent Registry record does not

Check:

- Verify agent status is ACTIVE.
- Runtime OAuth client is associated with the agent.
- Mapper found the correct OAuth client / `agent_id` purpose.
- Restricted sync token can call `agent-registry/register`.
- `entity_id` supplied to Agent Registry is the Vault-generated Identity entity ID.

### Agent registration exists but Vault cannot resolve actor

Check:

- Actor token `sub`.
- Alias `name`.
- OAuth Resource Server profile mount accessor.
- Issuer/profile binding.

The most common mistake is assuming the actor token `sub` without decoding a real actor token.

## 13.3 Token exchange

### `invalid_client`

Ensure the credentials are for the **Course Vault Token Exchange OIDC application**, not the Subject app or Actor app.

### Actor validation / delegation denied

Check:

- `Require actor token` is enabled.
- Subject token contains/carries `may_act` data.
- `may_act` properties match the actor token claims.
- `Skip default actor validation` is not enabled unless using Actor Criteria intentionally.

### `invalid_authorization_details`

Check:

- `vault:path_access` exists.
- Token Exchange OIDC application restricts/allows that ADT.
- JSON schema uses `path` and a `capabilities` array.
- Runtime path exactly matches the KV v2 API path.

## 13.4 Vault delegated JWT

### JWT validation failure

Check:

- `iss` exactly matches configured issuer.
- JWKS URL is reachable.
- JWT access token is signed with an allowed algorithm.
- Clock skew/time is correct.
- `aud` contains `vault-course-tools`.

### Token exchange succeeds but Vault returns 403 and audit has `auth.entity_id=null`

Vault received the JWT but did not resolve it to a Vault Identity entity. Read both subject and actor aliases and verify nonempty `issuer` and `external_id`, in addition to `name`, `canonical_id`, and `mount_accessor`. An issuer cannot be added after alias creation; repair the alias using [13A-VALIDATED-SETUP-TROUBLESHOOTING.md](13A-VALIDATED-SETUP-TROUBLESHOOTING.md).

### Agent registration required / not found

Check the actor entity registration:

```bash
curl -sS \
  -H "X-Vault-Token: $VAULT_SYNC_TOKEN" \
  "$VAULT_ADDR/v1/agent-registry/registration/entity-id/$VAULT_AGENT_ENTITY_ID" | jq
```

### RAR no match

`vault:path_access.path` is exact-match. For KV v2 use:

```text
course-tools/data/premium-enrollment
```

not:

```text
course-tools/premium-enrollment
```

## 13.5 Tool returns HTTP 403 after Vault read succeeds

This is a downstream credential failure, not an IBM Verify/Vault authorization failure.

Compare:

- Vault `api_key` value.
- App `PREMIUM_API_EXPECTED_KEY`.

For the intentional negative test these values are supposed to differ.

## 13.6 Antenna / ngrok

### Public discovery URL fails

First confirm local transmitter:

```bash
curl -k https://localhost:9044/.well-known/ssf-configuration
```

Then start:

```bash
ngrok http https://localhost:9044
```

Then test:

```bash
curl https://<ngrok-domain>/.well-known/ssf-configuration
```

Do not configure the external event stream until the public discovery URL works.
