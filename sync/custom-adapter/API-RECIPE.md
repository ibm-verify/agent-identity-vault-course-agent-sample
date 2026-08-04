# Custom Synchronization API Recipe

This recipe documents the Vault operations performed by the reference synchronization so teams can implement the same behavior without Antenna.

## Goal

For one ACTIVE IBM Verify agent, create this Vault state:

```text
IBM Verify Agent ID                 -> lifecycle correlation metadata
Actor JWT runtime identity          -> Vault OAuth entity alias
Vault-generated Identity entity_id  -> Agent Registry entity_id
Agent Registry registration         -> course-tool-ceiling
```

## Prerequisites

- The Vault OAuth Resource Server profile for IBM Verify already exists.
- `VAULT_OAUTH_MOUNT_ACCESSOR` is known.
- `course-tool-ceiling` exists.
- A restricted `VAULT_SYNC_TOKEN` with the policy in `vault/policies/verify-agent-sync.hcl` is available.
- The IBM Verify Agent record includes the stable Agent ID and associated runtime OAuth client.
- You have decoded one actor JWT and confirmed the identity value that Vault must resolve.

> The examples below use placeholders. Do not use Vault root at steady state.

## Input example

See `examples/course-assistant-agent-event.json`.

```json
{
  "verifyAgentId": "<VERIFY_AGENT_ID>",
  "displayName": "Course Assistant",
  "status": "ACTIVE",
  "runtimeOAuthClientId": "<ACTOR_CLIENT_ID>",
  "runtimeActorIdentity": "<ACTOR_TOKEN_SUB_OR_EXPECTED_ALIAS>"
}
```

## 1. Find or create the Vault Identity entity

Use a stable entity name derived from the Verify Agent ID so a display-name change does not create duplicates.

```bash
ENTITY_NAME="verify-agent-${VERIFY_AGENT_ID}"
```

Try to read it:

```bash
curl -sS \
  -H "X-Vault-Token: $VAULT_SYNC_TOKEN" \
  "$VAULT_ADDR/v1/identity/entity/name/$ENTITY_NAME"
```

If it does not exist, create it:

```bash
curl -sS --request POST \
  -H "X-Vault-Token: $VAULT_SYNC_TOKEN" \
  -H 'Content-Type: application/json' \
  --data @- \
  "$VAULT_ADDR/v1/identity/entity" <<JSON
{
  "name": "$ENTITY_NAME",
  "policies": [],
  "metadata": {
    "source": "ibm-verify",
    "verify_agent_id": "$VERIFY_AGENT_ID",
    "verify_agent_display_name": "Course Assistant"
  }
}
JSON
```

Record the returned Vault-generated `data.id` as `VAULT_AGENT_ENTITY_ID`.

## 2. Create the OAuth entity alias

The alias is the bridge from the runtime actor JWT to the Vault Identity entity.

Use the actual identity value your Vault OAuth Resource Server profile resolves for the actor. Validate it from a real actor token before creating the alias.

`issuer` and `external_id` are mandatory OAuth bindings. Vault prohibits changing `issuer` after alias creation; an incomplete alias must be deleted and recreated.

```bash
curl -sS --request POST \
  -H "X-Vault-Token: $VAULT_SYNC_TOKEN" \
  -H 'Content-Type: application/json' \
  --data @- \
  "$VAULT_ADDR/v1/identity/entity-alias" <<JSON
{
  "name": "$RUNTIME_ACTOR_IDENTITY",
  "canonical_id": "$VAULT_AGENT_ENTITY_ID",
  "mount_accessor": "$VAULT_OAUTH_MOUNT_ACCESSOR",
  "issuer": "$VERIFY_ISSUER",
  "external_id": "$RUNTIME_ACTOR_IDENTITY",
  "custom_metadata": {
    "source": "ibm-verify",
    "verify_agent_id": "$VERIFY_AGENT_ID"
  }
}
JSON
```

Before creating a new alias, lookup the existing mapping and refuse to silently remap an alias that belongs to another entity:

```bash
curl -sS --request POST \
  -H "X-Vault-Token: $VAULT_SYNC_TOKEN" \
  -H 'Content-Type: application/json' \
  --data "{\"alias_name\":\"$RUNTIME_ACTOR_IDENTITY\",\"alias_mount_accessor\":\"$VAULT_OAUTH_MOUNT_ACCESSOR\"}" \
  "$VAULT_ADDR/v1/identity/lookup/entity"
```

## 3. Register the entity as an approved agent

An Identity entity alone is not an Agent Registry registration.

```bash
curl -sS --request POST \
  -H "X-Vault-Token: $VAULT_SYNC_TOKEN" \
  -H 'Content-Type: application/json' \
  --data @- \
  "$VAULT_ADDR/v1/agent-registry/register" <<JSON
{
  "display_name": "Course Assistant",
  "entity_id": "$VAULT_AGENT_ENTITY_ID",
  "description": "Course Assistant synchronized from IBM Verify",
  "owner": "<OWNER_OR_TEAM>",
  "ceiling_policies": ["course-tool-ceiling"],
  "optional_authorization_details": false
}
JSON
```

Record the returned Agent Registry registration ID.

## 4. Validate

```bash
curl -sS \
  -H "X-Vault-Token: $VAULT_SYNC_TOKEN" \
  "$VAULT_ADDR/v1/agent-registry/registration/entity-id/$VAULT_AGENT_ENTITY_ID" | jq .
```

Confirm:

```text
entity_id                      = VAULT_AGENT_ENTITY_ID
ceiling_policies               contains course-tool-ceiling
optional_authorization_details = false
```

## 5. Lifecycle handling

### ACTIVE / update

- Keep the same Vault entity for the same Verify Agent ID.
- Refresh metadata.
- Ensure the runtime alias is still correct.
- Create/update the Agent Registry registration.
- Re-enable the entity if your lifecycle design disables entities on suspension.

### SUSPENDED / DEPROVISIONED

Reference demo behavior:

1. Find the entity using the stable Verify Agent ID correlation.
2. Delete the Agent Registry registration.
3. Disable the Vault Identity entity.
4. Keep non-secret correlation metadata for audit/troubleshooting.

The exact lifecycle policy is an integration design choice, but the runtime result must be that a suspended/deprovisioned agent no longer satisfies Vault's Agent Registry requirement.

## Required implementation properties

- Idempotent upsert.
- One Vault entity per stable Verify Agent ID.
- Runtime alias derived from a validated actor-token identity.
- Never silently steal/remap an alias from another entity.
- One Agent Registry registration per entity.
- Restricted Vault provisioning token only.
- RAR required for this demo (`optional_authorization_details=false`).
- No credentials or full tokens in logs.
