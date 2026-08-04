# 1. Use Case and Expected Outcomes

## 1.1 Problem statement

AI agents often need to call tools that are protected by API keys or other credentials. Putting those credentials directly in an agent configuration creates standing privilege and makes rotation, revocation, and audit harder.

This cookbook demonstrates a single Course Assistant Agent that obtains a protected tool API key **just in time** from Vault after delegated authorization by IBM Verify.

## 1.2 Course scenarios

### Use Case A — Standard course

A user selects a standard course.

```text
User → Course Assistant → normal enrollment path → SUCCESS
```

No privileged tool credential is required.

### Use Case B — Premium course with an approved agent

A user selects a premium course.

```text
Human subject token
        +
Course Assistant actor token
        +
vault:path_access authorization detail
        ↓
IBM Verify Token Exchange
        ↓
Delegated JWT
        ↓
Vault validates JWT, identities, Agent Registry, policies and RAR
        ↓
Vault returns Premium Tool API key
        ↓
Course Assistant calls Premium Enrollment Tool
        ↓
SUCCESS
```

### Use Case C — Agent is not registered in Vault

The IBM Verify token exchange can still be valid, but Vault does not find the required actor Agent Registry registration.

Expected result:

```text
Vault denies the OAuth credential / secret access
No API key is returned
Premium enrollment fails
```

This proves that Vault Agent Registry is part of runtime enforcement.

### Use Case D — Wrong tool API key stored in Vault

The agent is registered and authorized, so Vault allows the secret read. However, the secret value is intentionally changed to an incorrect API key.

Expected result:

```text
IBM Verify token exchange     SUCCESS
Vault authorization           SUCCESS
Vault secret read             SUCCESS
Protected Premium Tool        HTTP 403
Premium enrollment            FAILED
```

This proves that the tool credential truly comes from Vault and is actually required by the downstream tool.

## 1.3 What this demo proves

- Human and agent identities remain distinct.
- The Course Assistant is explicitly onboarded and governed in both IBM Verify and Vault.
- The agent's runtime identity is its actor OAuth token, not a free-form name passed in a request.
- Vault validates an externally issued OAuth JWT directly; the agent does not perform a separate Vault login to get another runtime token.
- Vault Agent Registry constrains the actor through ceiling policies.
- RAR (`vault:path_access`) narrows access to one exact Vault path and capability.
- The agent never stores the premium tool API key permanently.
- Synchronization credentials and runtime credentials are separated.

## 1.4 Non-goals

- No A2A communication.
- No notification/receipt agent.
- No transaction token.
- No LLM-based authorization decision.
- No certificate/PKI tool-authentication use case in the main flow.

## 1.5 Success criteria

The cookbook is complete when all of these work:

1. Course Assistant exists in IBM Verify and is ACTIVE.
2. Its actor OIDC client is associated with the agent.
3. The agent is synchronized into Vault as an Identity entity, OAuth alias, and Agent Registry registration.
4. Human login produces a subject JWT.
5. Client Credentials produces the actor JWT.
6. Token Exchange OIDC application issues a delegated JWT with the expected audience and `vault:path_access`.
7. Vault accepts that JWT and returns the premium tool API key.
8. Standard course enrollment succeeds.
9. Premium course enrollment succeeds.
10. Removing/invalidating the agent registration causes Vault denial.
11. Changing only the Vault secret causes the protected tool to return HTTP 403.
