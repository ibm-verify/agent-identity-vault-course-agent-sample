# IBM Verify + HashiCorp Vault — Secure Course Agent Tool Credentials

A customer-focused, end-to-end reference implementation for securing an AI agent's tool credential with **IBM Verify delegated authorization** and **HashiCorp Vault native AI agent support**.

## Objective

A human user signs in to a Course Portal and asks a single **Course Assistant Agent** to enroll in a course.

- Standard courses use the normal application path.
- Premium courses use a protected enrollment tool that requires an API key.
- The API key is **not stored in the agent, browser, source code, or prompt**.
- The API key is stored in Vault and is released only when Vault accepts an IBM Verify delegated JWT for a **registered agent** and the requested `vault:path_access` is authorized.

The primary runtime story is:

```text
User → Course Assistant → IBM Verify Token Exchange → Delegated JWT
     → Vault validates user + agent + Agent Registry + policy + RAR
     → Vault returns tool API key → Premium Enrollment Tool → Success
```

The agent onboarding story happens first:

```text
IBM Verify Course Assistant Agent
        + associated Actor OIDC client
        ↓
Synchronization adapter
(Antenna reference implementation OR your own integration)
        ↓
Vault Identity Entity + OAuth Alias + Agent Registry registration
```

![End-to-end architecture](docs/images/architecture/00-end-to-end-architecture.png)

## Start here

1. Read [START-HERE.md](START-HERE.md).
2. Follow the cookbook in numbered order under [`docs/`](docs/).
3. Use [`docs/VALUES-WORKSHEET.md`](docs/VALUES-WORKSHEET.md) to record your tenant-specific values.
4. Use the included Postman collection after the IBM Verify and Vault configuration is complete.
5. Replace screenshot placeholders as you configure your tenant; see [`docs/SCREENSHOT-CHECKLIST.md`](docs/SCREENSHOT-CHECKLIST.md).

## Important compatibility gate

This use case stores a tool API key in a Vault **KV v2** secrets engine. A Vault cluster running in **PKI-only mode** rejects API requests to non-PKI secrets-engine mounts. The first cookbook step therefore verifies whether your Vault environment supports both the native AI-agent functions required here and KV secrets.

If the compatibility gate fails, **do not continue with the API-key use case on that cluster**. Use a Vault Enterprise environment where the required features and KV secrets are permitted.

## Repository map

```text
.
├── START-HERE.md
├── docs/                       Customer-facing cookbook, in execution order
├── app/                        Runnable Course Portal / Premium Tool demo
├── config/                     Course catalog
├── verify/                     ADT, token examples, helper scripts
├── vault/                      Policies, OAuth profile, bootstrap/runtime scripts
├── sync/
│   ├── antenna/                Reference synchronization recipe
│   └── custom-adapter/         Vendor-neutral synchronization contract
├── postman/                    End-to-end Postman collection + environment
└── scripts/                    Top-level prerequisite/start helpers
```

## Design principles

- One human subject and one Course Assistant actor.
- No A2A flow.
- No transaction token.
- Token exchange uses a dedicated **OIDC application with the Token Exchange grant** and configures the access-token audience that Vault validates.
- Vault Agent Registry is part of runtime enforcement; it is not merely inventory.
- Antenna is a reference synchronization implementation, not an architectural dependency.
- Root/admin Vault credentials are used only for initial bootstrap. Synchronization uses a restricted provisioning token. Runtime uses the IBM Verify delegated JWT directly.
