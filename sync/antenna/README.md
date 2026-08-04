# Antenna Reference Recipe — IBM Verify Agent → Vault Agent Registry

This folder explains **what the reference synchronization does** and how to run it. The runtime cookbook does not depend on Antenna specifically; a customer can replace it with any adapter that implements the contract in [`../custom-adapter/INTEGRATION-CONTRACT.md`](../custom-adapter/INTEGRATION-CONTRACT.md).

## Objective

When the Course Assistant is created/activated in IBM Verify, synchronize the same agent into Vault as:

```text
Vault Identity Entity
+ OAuth Alias for the agent runtime identity
+ Vault Agent Registry Registration
+ course-tool-ceiling
```

When the agent is suspended/deprovisioned, remove/disable the corresponding Vault governance objects according to the demo lifecycle rule.

## Credential model

### Bootstrap only

A Vault admin/root-equivalent credential creates the synchronization policy and short-lived restricted token.

### Synchronization

Antenna receiver uses:

```text
VAULT_SYNC_TOKEN
```

The reference implementation exposes that token to Antenna as `VAULT_TOKEN` because that is the variable consumed by the receiver script. The value must be the **restricted sync token**, not root.

### Runtime

The Course Assistant never uses this token. Runtime Vault access uses the IBM Verify delegated JWT directly.

## Architecture

```text
IBM Verify Agent Registry
        │ lifecycle event
        ▼
ngrok public HTTPS URL
        ▼
Antenna Transmitter :9044
        │ normalize/enrich agent record
        ▼
SSF Stream
        ▼
Antenna Receiver :9043
        │ restricted Vault sync token
        ▼
Vault Identity + Alias + Agent Registry
```

## Prerequisites

Before starting Antenna:

```text
[ ] Main cookbook Vault compatibility gate passed
[ ] Vault OAuth Resource Server profile created
[ ] VAULT_OAUTH_MOUNT_ACCESSOR recorded
[ ] course-tool-ceiling policy exists
[ ] restricted VAULT_SYNC_TOKEN created
[ ] Course Assistant exists in IBM Verify
[ ] Actor OAuth client is associated with Course Assistant
[ ] Actor token identity has been decoded/validated
[ ] Docker/Compose or Colima is available
[ ] ngrok is installed and authenticated
[ ] envsubst/gettext is available
```

## Step A1 — Prepare reference implementation

```bash
cd sync/antenna/reference-implementation
cp scripts/00_env.sh scripts/00_env.local.sh
```

Edit `scripts/00_env.local.sh`. All reference scripts automatically prefer this local file when present, keeping the checked-in template free of real credentials.

Set:

```bash
VERIFY_TENANT_HOST="<tenant-host>"
VERIFY_CLIENT_ID="<Verify API client that can read agent records>"
VERIFY_CLIENT_SECRET="<secret>"
VERIFY_ISSUER="https://<tenant-host>/oauth2"

VAULT_ADDR_HOST="http://127.0.0.1:8200"
VAULT_ADDR_FROM_ANTENNA="http://host.docker.internal:8200"
VAULT_TOKEN="<RESTRICTED_VAULT_SYNC_TOKEN>"
VAULT_POLICY="course-tool-ceiling"
VAULT_MOUNT_ACCESSOR="<VAULT_OAUTH_MOUNT_ACCESSOR>"
```

> **Prerequisite note:** The Verify sync API client is needed because the transmitter may enrich a lifecycle event by reading the complete Agent Registry record, including OAuth-client metadata.

## Step A2 — Start local Antenna services

```bash
source scripts/00_env.local.sh
bash scripts/00_mac_prereq_check.sh
bash scripts/01_cleanup.sh
bash scripts/02_generate_san_certs.sh
bash scripts/03_render_templates.sh
bash scripts/04_start_lab.sh
```

Validate local discovery:

```bash
curl -k https://localhost:9044/.well-known/ssf-configuration | python3 -m json.tool
```

Do not continue until this returns SSF metadata.

## Step A3 — Start ngrok

In a separate terminal:

```bash
ngrok http https://localhost:9044
```

Copy the forwarding URL, for example:

```text
https://abc123.ngrok-free.app
```

Set:

```bash
export NGROK_URL="https://abc123.ngrok-free.app"
```

Update `scripts/00_env.local.sh`, rerender, and restart so transmitter metadata contains the public URL:

```bash
source scripts/00_env.local.sh
bash scripts/03_render_templates.sh
bash scripts/04_start_lab.sh
```

Validate publicly:

```bash
curl -sS "$NGROK_URL/.well-known/ssf-configuration" | python3 -m json.tool
```

### Screenshot placeholder

Replace after setup:

`../../docs/images/screenshots/placeholders/14-antenna-ngrok.png`

## Step A4 — Create receiver stream

```bash
bash scripts/05_create_stream_json.sh
bash scripts/06_create_receiver_stream.sh
```

## Step A5 — Understand the mapping before sending real events

The reference mapper implements this rule:

```text
Verify Agent ACTIVE
+ runtime OAuth client present / purpose agent_id
        ↓
UPSERT Vault entity + alias + Agent Registry
```

A DRAFT agent or an agent without a runtime OAuth client is not registered for runtime use.

The stable IDs are intentionally different:

```text
Verify Agent ID              → lifecycle correlation
Verify OAuth client / token  → runtime alias identity
Vault Identity entity_id     → Agent Registry entity_id
Vault Agent Registry id      → registration id
```

## Step A6 — Run local lifecycle tests

```bash
bash scripts/07_test_draft_event.sh
bash scripts/08_test_active_event.sh
bash scripts/11_verify_vault.sh
bash scripts/09_test_delete_event.sh
bash scripts/11_verify_vault.sh
```

Watch logs:

```bash
bash scripts/10_watch_logs.sh
```

## Step A7 — Configure real Verify event delivery

Configure the appropriate IBM Verify management event/webhook delivery to:

```text
${NGROK_URL}/sources/push_src_1/events
```

Then create/update the Course Assistant as ACTIVE with its runtime OAuth client association.

Expected result:

```text
Vault entity created/updated
OAuth alias created/updated
Agent Registry registration created/updated
ceiling_policies includes course-tool-ceiling
optional_authorization_details = false
```

## Step A8 — Validate runtime identity mapping

After sync, compare:

```text
Actor access-token sub/client_id
        ↕
Vault OAuth alias name
        ↕
Vault entity_id
        ↕
Vault Agent Registry registration.entity_id
```

Read the alias itself and require all OAuth binding fields:

```text
name           = actor token act.sub/client identity
external_id    = same runtime actor identity
issuer         = exact delegated JWT iss
mount_accessor = course-verify OAuth profile accessor
canonical_id   = synchronized actor Vault entity
```

An alias that merely exists is insufficient. If `issuer` or `external_id` is empty, Vault audit shows `auth.entity_id=null` and the OAuth JWT read returns 403. Because issuer is immutable, delete and recreate that alias using the repair procedure in `docs/13A-VALIDATED-SETUP-TROUBLESHOOTING.md`.

If actor token `sub` does not equal the OAuth client ID in your tenant, adapt `verify_agent_registry_mapper.js.template` so the alias matches the actual runtime identity claim Vault resolves.

## What to copy if you build your own adapter

Do not copy Antenna-specific mechanics. Copy the behavior:

1. Receive agent lifecycle event.
2. Resolve stable Verify Agent ID.
3. Resolve runtime actor identity/OAuth client.
4. Upsert Vault entity.
5. Upsert OAuth alias bound to the Verify OAuth Resource Server profile.
6. Upsert Agent Registry registration with `course-tool-ceiling` and RAR required.
7. Deactivate/remove registration when the Verify agent is suspended/deprovisioned.

That contract is documented in the custom-adapter folder.
