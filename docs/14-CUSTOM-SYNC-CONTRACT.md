# 14. Custom Synchronization Contract

Antenna is only one implementation. This document defines the contract a replacement integration must satisfy.

## 14.1 Input

The adapter needs agent lifecycle data from IBM Verify, directly from an event or by enriching the event through the Agent Registry API.

Minimum logical fields:

```json
{
  "id": "<VERIFY_AGENT_ID>",
  "displayName": "Course Assistant",
  "status": "ACTIVE",
  "owners": ["<owner>"],
  "tags": ["course"],
  "oauthClients": [
    {
      "clientId": "<ACTOR_CLIENT_ID>",
      "purposes": ["agent_id"]
    }
  ]
}
```

## 14.2 Credential used by the adapter

Use a restricted Vault provisioning token.

Do not use:

- the Course Assistant actor token,
- the delegated runtime JWT,
- a root token after bootstrap.

## 14.3 ACTIVE / upsert behavior

### Step 1 — Find or create Vault Identity entity

Stable correlation should use the IBM Verify Agent ID, for example:

```text
entity name = verify-agent-<VERIFY_AGENT_ID>
```

Store metadata such as:

```text
source=ibm-verify
verify_agent_id=<id>
verify_agent_display_name=Course Assistant
```

Capture the Vault-generated:

```text
entity_id
```

### Step 2 — Create/update OAuth alias

Alias must bind the runtime actor identity to the entity.

```text
name           = actor runtime identity (validate ACTOR_TOKEN.sub)
canonical_id   = Vault entity_id
mount_accessor = Verify OAuth Resource Server profile accessor
```

The reference Antenna implementation normally derives the runtime alias from the associated OAuth client. Validate this against a real actor JWT in your tenant.

### Step 3 — Create/update Agent Registry registration

```json
{
  "display_name": "Course Assistant",
  "entity_id": "<VAULT_ENTITY_ID>",
  "description": "Synchronized from IBM Verify",
  "owner": "<owner>",
  "ceiling_policies": ["course-tool-ceiling"],
  "optional_authorization_details": false
}
```

## 14.4 Suspension/deprovision behavior

Recommended demo behavior:

```text
Verify status becomes SUSPENDED/DEPROVISIONED/DELETED
        ↓
Delete Agent Registry registration
        +
Disable Vault Identity entity
```

This ensures the actor no longer satisfies Vault's registered-agent requirement.

Production lifecycle behavior should be aligned with your governance and recovery requirements.

## 14.5 Idempotency

The adapter should be safe to run repeatedly.

- Find entity by stable agent correlation before creating.
- Refuse to silently reassign an existing alias to another entity.
- Update an existing Agent Registry record instead of creating duplicates.
- Vault allows one Agent Registry registration per entity.

## 14.6 Required Vault API operations

Typical paths:

```text
identity/entity
identity/entity/name/*
identity/entity/id/*
identity/entity-alias
identity/lookup/entity
agent-registry/register
agent-registry/registration/*
```

## 14.7 Acceptance test for any custom adapter

```text
1. Create/activate Course Assistant in IBM Verify.
2. Adapter runs.
3. Vault entity appears.
4. OAuth alias appears and matches actor runtime identity.
5. Agent Registry registration appears with course-tool-ceiling.
6. Premium runtime succeeds.
7. Suspend agent in Verify.
8. Adapter removes/disables registration/entity.
9. Premium runtime is denied by Vault.
10. Reactivate and resynchronize.
11. Premium runtime succeeds again.
```
