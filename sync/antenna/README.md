# Verify–Vault Agent Sync Using Antenna

> **Document scope:** This guide explains how an AI Agent registered in IBM Verify is automatically synchronized into HashiCorp Vault via the **Verify Antenna** integration, what gets created on the Vault side, and how to install and configure the Antenna Transmitter and Receiver components.
> This folder explains **what the reference synchronization does** and how to run it. The runtime cookbook does not depend on Antenna specifically; a customer can replace it with any adapter that implements the contract in [`../custom-adapter/INTEGRATION-CONTRACT.md`](../custom-adapter/INTEGRATION-CONTRACT.md).

---

## Table of Contents

1. [Overview](#1-overview)
2. [Background](#2-background)
3. [Architecture](#3-architecture)
4. [Prerequisites](#4-prerequisites)
5. [Install and Setup](#5-install-and-setup)

---

## 1. Overview

When an **Agent Developer** registers an AI Agent into the **Agent Registry** in IBM Verify, the registration event is automatically propagated to **HashiCorp Vault** through **Verify Antenna**. This Verify-to-Vault agent sync is a **uni-directional (one-way) sync** that ensures:

- The AI Agent is registered in Vault's agent registry.
- A corresponding **Vault Entity** is created for the agent.
- An **Entity Alias** is created to map the Verify agent identity to the Vault entity.
- Appropriate **Vault Policies** are attached to the entity so the agent has least-privileged access to its secrets.

This automated sync removes the need for Agent Developers to manually register agents in two separate systems and keeps Verify as the single source of truth for agent identity.

---

## 2. Background

### Why Both Verify and Vault?

IBM Agent Identity relies on two complementary products to fully secure an AI Agent's interactions:

| Concern | Product | Role |
|---|---|---|
| Identity & authorisation tokens | **IBM Verify** | Issues least-privileged on-behalf-of (OBO) tokens after validating consent and policy |
| Secrets & credentials storage | **HashiCorp Vault** | Stores bootstrap secrets and last-mile credentials instead of hard-coding them in the agent |

### Problem Without Automation

Without automated sync, an Agent Developer must:

1. Register the AI Agent in IBM Verify.
2. **Separately** log in to Vault and manually create a matching entity, alias, and policy set.
3. Repeat this for **every agent** in the fleet — a process that becomes error-prone and time-consuming at scale.

### What IBM Agent Identity Solves Today

IBM Agent Identity's **initial release** addresses this pain point by providing a **uni-directional agent sync from Verify to Vault**. As soon as an agent is registered (or updated, or deregistered) in Verify, the change is automatically reflected in Vault with no manual intervention required.

### Roadmap

> Bi-directional agent sync using adapters or Verify Antenna is planned for upcoming releases. This will allow agents onboarded directly in Vault to also appear in Verify's Agent Registry.

---

## 3. Architecture

This section describes the three primary components involved in the Verify–Vault agent sync and how they work together. Each component operates independently but is connected through a standardised event-driven flow using the **OpenID Shared Signals Framework (SSF)**.

### 3.1 IBM Agent Identity in IBM Verify SaaS

**IBM Agent Identity** is part of the IBM Verify portfolio. It provides a centralised Agent Registry where Agent Developers can onboard, manage, and govern AI agents as first-class identities. The registry tracks each agent's metadata, authentication bindings, consent records, and policy entitlements.

When an agent lifecycle event occurs (create, update, or delete), IBM Verify fires an internal event that the **Antenna Transmitter** picks up and converts into a standardised Antenna Event for downstream delivery.

**Key capabilities relevant to this sync:**

- Serves as the **single source of truth** for AI agent identity.
- Issues **least-privileged on-behalf-of (OBO) tokens** after validating consent and policy.
- Hosts the **Antenna Transmitter** that publishes agent lifecycle events to the Antenna Bus.
- Maintains full audit trail of all agent registration and policy changes.

> 📖 **Reference:** [IBM Agent Identity documentation](https://www.ibm.com/docs/agent-identity)

---

### 3.2 IBM Verify Antenna 26.03.0

**IBM Verify Antenna** is a lightweight, self-hosted container that enables the seamless exchange of security events and risk signals using the **OpenID Shared Signals Framework (SSF)**. It acts as the event transport layer between IBM Verify and external systems such as HashiCorp Vault.

Verify Antenna can operate in two modes within the SSF:

| Mode | Role | What it does in this sync |
|---|---|---|
| **Transmitter** | Event producer | Ingests agent lifecycle events from IBM Verify, transforms them into Antenna Events using a JavaScript transform script, and publishes them securely to the Antenna Bus |
| **Receiver** | Event consumer | Subscribes to the Antenna Bus, receives agent events, and converts them into API calls against HashiCorp Vault to create, update, or delete agent entities, aliases, and policies |

As a transmitter, Verify Antenna ingests events from sources such as databases, audit streams, and internal registries, transforms them into standards-based or custom event formats, and transmits them securely as defined by the SSF framework.

As a receiver, Verify Antenna consumes events and converts them into actions on target systems — for example, revoking user sessions when risky behaviour is detected, or (in this case) synchronising agent registrations into Vault.

**Key capabilities relevant to this sync:**

- Provides **durable, at-least-once event delivery** between Verify and Vault.
- Supports **JavaScript transform scripts** for flexible payload mapping (Verify → Antenna Event → Vault).
- Uses **HMAC-signed payloads** to ensure event integrity in transit.
- Self-hosted container — deployable alongside your Vault cluster for minimal network latency.

> 📖 **Reference:** [IBM Verify Antenna 26.03.0 documentation](https://www.ibm.com/docs/en/verify-antenna/26.03.0)

---

### 3.3 HashiCorp Vault Enterprise 2.0.3

**HashiCorp Vault Enterprise 2.0.3** introduces native support for AI agents through two related capabilities that are used directly by this sync:

| Vault Capability | Minimum Version | Purpose in this sync |
|---|---|---|
| **Agent Registry** | 2.0.3 | Enrolls, governs, and audits agentic identities as first-class Vault entities |
| **OAuth Resource Server** | 2.0.3 | Validates OAuth 2.0 / JWT tokens issued by IBM Verify so agents can authenticate to Vault using their Verify-issued identity token |

When the Antenna Receiver processes an `agent.created` event, it makes three sequential calls to the Vault API:

1. **Create Entity** — registers the agent as a named identity in Vault's identity store.
2. **Create Entity Alias** — binds the agent's JWT `sub` claim (issued by IBM Verify) to the Vault entity using the JWT auth method mount.
3. **Attach Policies** — grants the entity least-privileged read access to its designated secret paths under `secret/agents/<agent-id>/`.

For `agent.updated` and `agent.deleted` events, Vault resources are updated or cleaned up accordingly.

**Key capabilities relevant to this sync:**

- **Agent Registry** provides a governed, auditable store of agentic identities — separate from human user identities.
- **JWT/OIDC auth method** accepts tokens signed by IBM Verify, enabling passwordless agent authentication.
- **Policy engine** enforces least-privilege access so each agent can only read its own secrets.
- Full **audit log** of all agent token issuance and secret access events.

> 📖 **Reference:** [HashiCorp Vault — Native AI Agent Support](https://developer.hashicorp.com/vault/docs/concepts/native-ai-agent-support)

---

### 3.4 End-to-End Data Flow

The sequence below shows how the three components interact from the moment an Agent Developer registers a new agent to the moment that agent's Vault identity is ready.

```
IBM Agent Identity - Agent Registry
        │ lifecycle event
        ▼
ngrok public HTTPS URL^
        ▼
Verify Antenna Transmitter :9044
        │ normalize/enrich agent record
        ▼
SSF Stream
        ▼
Verify Antenna Receiver :9043
        │ restricted Vault sync token
        ▼
Vault Identity + Alias + Agent Registry
```
^ Note: Having ngrok public URL is only for developement purpose. Not recommended for production.

### 3.5 Component Responsibilities Summary

| Component | Location | Responsibility |
|---|---|---|
| **IBM Agent Identity (Verify)** | IBM Verify SaaS tenant | Single source of truth for agent identity; fires lifecycle events to Antenna Transmitter |
|**ngrok** | Public URL | |
| **Antenna Transmitter** | Embedded in Verify Antenna (self-hosted) | Transforms Verify agent events into standardised Antenna Events and publishes to Antenna Bus |
| **SSF Stream** | Verify Antenna infrastructure | Routes and durably delivers events from transmitters to receivers |
| **Antenna Receiver** | Verify Antenna (self-hosted, Vault-adjacent) | Consumes Antenna Events and applies CRUD operations on Vault entities, aliases, and policies |
| **HashiCorp Vault Enterprise** | Customer-managed Vault cluster | Stores agent identities, secrets, and enforces least-privilege policies |

---


## 4. Prerequisites

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
### Credential model

#### Bootstrap only

A Vault admin/root-equivalent credential creates the synchronization policy and short-lived restricted token.

#### Synchronization

Antenna receiver uses:

```text
VAULT_SYNC_TOKEN
```

The reference implementation exposes that token to Antenna as `VAULT_TOKEN` because that is the variable consumed by the receiver script. The value must be the **restricted sync token**, not root.

#### Runtime

The Course Assistant never uses this token. Runtime Vault access uses the IBM Verify delegated JWT directly.

## 5. Install and Setup 

### Step A1 — Prepare reference implementation

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

### Step A2 — Start local Antenna services

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

### Step A3 — Start ngrok

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

#### Screenshot placeholder

Replace after setup:

`../../docs/images/screenshots/placeholders/14-antenna-ngrok.png`

### Step A4 — Create receiver stream

```bash
bash scripts/05_create_stream_json.sh
bash scripts/06_create_receiver_stream.sh
```

### Step A5 — Understand the mapping before sending real events

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

### Step A6 — Run local lifecycle tests

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

### Step A7 — Configure real Verify event delivery

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

### Step A8 — Validate runtime identity mapping

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

### What to copy if you build your own adapter

Do not copy Antenna-specific mechanics. Copy the behavior:

1. Receive agent lifecycle event.
2. Resolve stable Verify Agent ID.
3. Resolve runtime actor identity/OAuth client.
4. Upsert Vault entity.
5. Upsert OAuth alias bound to the Verify OAuth Resource Server profile.
6. Upsert Agent Registry registration with `course-tool-ceiling` and RAR required.
7. Deactivate/remove registration when the Verify agent is suspended/deprovisioned.

That contract is documented in the custom-adapter folder.
