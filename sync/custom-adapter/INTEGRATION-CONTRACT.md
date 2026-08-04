# Vendor-Neutral Agent Synchronization Integration Contract

Use this document when you do not want to run the included Antenna scripts. For concrete Vault HTTP calls, see `API-RECIPE.md`.

## Purpose

Synchronize an IBM Verify Agent Registry record into the Vault objects required by native AI agent authorization.

## Inputs

At minimum:

```json
{
  "verifyAgentId": "<stable-agent-id>",
  "displayName": "Course Assistant",
  "status": "ACTIVE",
  "owner": "<owner/team>",
  "runtimeOAuthClientId": "<actor-client-id>"
}
```

Your integration may receive only an event ID and then call the IBM Verify Agent Registry API to retrieve the full record.

## Configuration inputs

```text
Vault address / namespace
Restricted Vault synchronization token
Vault OAuth Resource Server profile mount accessor
Exact IBM Verify issuer (`iss`)
Agent ceiling policy name = course-tool-ceiling
Runtime alias mapping rule
```

## ACTIVE / UPSERT algorithm

```text
1. Find entity by stable correlation metadata/name based on Verify Agent ID.
2. If missing, create Vault Identity entity.
3. Determine runtime actor identity that will appear in the actor JWT.
4. Find/create Vault OAuth alias:
     name = runtime actor identity
     canonical_id = Vault entity_id
     mount_accessor = Verify OAuth Resource Server profile accessor
     issuer = exact delegated JWT iss
     external_id = runtime actor identity (act.sub)
5. Find Agent Registry record by entity_id.
6. Create/update registration:
     display_name = Course Assistant
     entity_id = Vault entity_id
     ceiling_policies = [course-tool-ceiling]
     optional_authorization_details = false
7. Return/log non-secret correlation IDs.
```

## SUSPEND / DEPROVISION algorithm

Reference demo behavior:

```text
1. Find Vault entity by stable Verify Agent ID correlation.
2. Delete Agent Registry registration.
3. Disable Vault Identity entity.
4. Preserve audit/correlation metadata.
```

## Required properties

- Idempotent.
- Never remap an existing alias to another entity silently.
- Create OAuth aliases with issuer and external_id initially; issuer is immutable after creation.
- One Agent Registry registration per entity.
- Never use root at steady state.
- Never provide the synchronization token to the agent runtime.
- Keep RAR required (`optional_authorization_details=false`).
- Log IDs/status, not credentials.

## Acceptance test

A custom adapter is compatible when it passes the sequence in `docs/14-CUSTOM-SYNC-CONTRACT.md`.
