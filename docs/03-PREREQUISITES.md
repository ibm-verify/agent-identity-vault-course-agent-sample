# 3. Prerequisites and Values Worksheet

## 3.1 Required software

- IBM Verify SaaS tenant with administrative access.
- Vault Enterprise **2.0.3 or later** with native AI Agent Registry and OAuth Resource Server features available.
- A Vault environment where the KV v2 secrets engine is permitted for this use case.
- Node.js 18 or later.
- `curl`.
- `jq`.
- Vault CLI.
- Postman (recommended for learning and troubleshooting).

For the Antenna synchronization reference implementation only:

- Docker + Docker Compose, or Colima + Docker CLI on macOS.
- `ngrok`.
- `envsubst` / gettext.

> **Prerequisite note — PKI-only Vault:** A cluster operating in PKI-only mode rejects API requests to non-PKI secrets-engine mounts. Because this cookbook stores an API key in KV v2, run the compatibility gate before doing any other setup. If KV is not permitted, use a non-PKI-only Vault environment for this API-key use case.

## 3.2 Required IBM Verify permissions

The administrator must be able to:

- Create users or use an existing test user.
- Create an Agent Registry agent.
- Create/associate OIDC applications.
- Configure Token Exchange on an OIDC application.
- Configure OIDC endpoint/introspection mappings.
- Create Authorization Detail Types.
- Create an API client for synchronization if Antenna needs to read full agent records.

## 3.3 Required Vault bootstrap permissions

An initial Vault administrator/root-equivalent credential is required only to:

- Run the compatibility gate.
- Activate/configure OAuth Resource Server support.
- Create ACL policies.
- Create a restricted synchronization token.
- Enable/configure KV v2.
- Store the initial demo secret.

After bootstrap, the synchronization integration should use its restricted token; the Course Assistant runtime should use only the delegated JWT.

## 3.4 Values worksheet

Copy [VALUES-WORKSHEET.md](VALUES-WORKSHEET.md) and fill it in as you go.

Do not copy IDs or URLs from screenshots. Screenshots show **where** to configure; the worksheet stores **your** values.

## 3.5 Recommended names

| Object | Recommended name |
|---|---|
| IBM Verify Agent | `Course Assistant` |
| Actor OIDC application | `Course Assistant Runtime` |
| Subject OIDC application | `Course Portal` |
| Token Exchange OIDC application | `Course Vault Token Exchange` |
| Vault OAuth profile | `course-verify` |
| Vault audience | `vault-course-tools` |
| Subject Vault policy | `course-tool-subject` |
| Agent ceiling policy | `course-tool-ceiling` |
| KV mount | `course-tools` |
| Secret API path | `course-tools/data/premium-enrollment` |

## 3.6 Before you continue

You should have:

```text
[ ] IBM Verify admin access
[ ] Vault Enterprise admin/root bootstrap access
[ ] Node.js 18+
[ ] curl + jq + Vault CLI
[ ] Postman
[ ] Antenna prerequisites only if using the reference synchronization path
```
