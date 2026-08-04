# 7. Synchronize the Course Assistant to Vault

This is the bridge between **agent in IBM Verify** and **runtime agent enforcement in Vault**.

## What must exist in Vault after synchronization

```text
Course Assistant Vault Identity entity
        +
OAuth alias that resolves the actor JWT identity
        +
Vault Agent Registry registration
        +
course-tool-ceiling policy
```

An Identity entity by itself is not enough. The Agent Registry registration is what marks the entity as an approved agent and applies its authorization ceiling.

## Prerequisites

- Vault OAuth profile and `VAULT_OAUTH_MOUNT_ACCESSOR` are ready.
- `course-tool-ceiling` policy exists.
- Restricted `VAULT_SYNC_TOKEN` exists.
- Course Assistant exists in IBM Verify and is ACTIVE.
- Actor OAuth client is associated with the agent.

## Choose one synchronization method

### Option A — Antenna reference implementation

Use the included recipe when you want to reproduce the reference integration.

Go to:

```text
sync/antenna/README.md
```

High-level flow:

```text
IBM Verify agent lifecycle event
        ↓
Antenna Transmitter
        ↓
SSF stream
        ↓
Antenna Receiver
        ↓ restricted VAULT_SYNC_TOKEN
Vault Identity + Alias + Agent Registry
```

Antenna is a reference implementation, not a mandatory architectural component.

### Option B — Your own synchronization adapter

Use:

```text
sync/custom-adapter/INTEGRATION-CONTRACT.md
sync/custom-adapter/API-RECIPE.md
```

The integration contract defines required behavior; the API recipe shows the concrete Vault entity, alias, and Agent Registry calls. Any implementation is acceptable—Java/Python service, Lambda, event processor, IAM integration—if it implements the same contract.

## What our reference synchronization does

For an ACTIVE Verify agent with a runtime OAuth client:

1. Receive the agent lifecycle event.
2. Read/enrich the full Verify Agent record when necessary.
3. Use the stable Verify Agent ID to find/create the Vault Identity entity.
4. Create the OAuth alias for the runtime actor identity using the Verify OAuth Resource Server profile binding.
   The alias must include `issuer=<delegated JWT iss>` and `external_id=<actor act.sub>` when it is created.
5. Register the Vault entity in Agent Registry with `course-tool-ceiling`.
6. Keep `optional_authorization_details=false` so RAR remains required.
7. On suspension/deprovision, remove/disable the registration/entity according to your lifecycle policy.

## Expected Vault mapping

![Identity sync mapping](images/architecture/01-agent-identity-sync-mapping.png)

### Example Agent Registry record

```json
{
  "display_name": "Course Assistant",
  "entity_id": "<VAULT_GENERATED_ENTITY_ID>",
  "description": "IBM Verify Course Assistant",
  "owner": "<team-or-owner>",
  "ceiling_policies": ["course-tool-ceiling"],
  "optional_authorization_details": false
}
```

## Validate after synchronization

```bash
export VAULT_TOKEN="$VAULT_SYNC_TOKEN"
bash vault/scripts/05_validate_synced_agent.sh
```

You should be able to confirm:

```text
[ ] Vault entity exists
[ ] OAuth alias exists
[ ] Alias resolves the runtime actor identity
[ ] Alias issuer exactly matches the delegated JWT iss
[ ] Alias external_id matches actor act.sub
[ ] Agent Registry registration exists
[ ] Registration entity_id matches the Vault entity
[ ] ceiling_policies contains course-tool-ceiling
[ ] optional_authorization_details is false
```


## STOP CHECKPOINT

Do not configure runtime OBO until the same Course Assistant is visible and correctly mapped in both systems.

After this checkpoint passes, return to the main cookbook and complete:

```text
docs/07A-STORE-TOOL-SECRET-BEFORE-VERIFY.md
```

That step validates the new non-PKI license, enables KV v2, stores the API key, and proves an administrator can read it. Only after it passes should you continue to:

```text
docs/08-CONFIGURE-VERIFY-OBO.md
```
