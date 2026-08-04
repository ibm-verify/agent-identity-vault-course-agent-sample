# 9. Reconfirm the Protected Tool API Key After IBM Verify Configuration

The API key was intentionally created before Guide 8 in [07A-STORE-TOOL-SECRET-BEFORE-VERIFY.md](07A-STORE-TOOL-SECRET-BEFORE-VERIFY.md). This chapter is now a short recheck before delegated-JWT smoke testing; the included scripts remain idempotent.

This is the credential the Course Assistant needs to call the Premium Enrollment Tool.

## Prerequisites

- Vault compatibility gate passed.
- Runtime policies exist.
- Agent synchronization is complete.
- You have a bootstrap/admin Vault token for this setup step.

## Step 9.1 — Enable KV v2 at `course-tools`

```bash
bash vault/scripts/06_enable_kv.sh
```

Expected mount:

```text
course-tools/
```

## Step 9.2 — Store the correct demo API key

The protected Course API in the sample application expects:

```text
course-premium-demo-key-2026
```

Store the same value in Vault:

```bash
bash vault/scripts/07_store_matching_tool_secret.sh
```

Logical KV command:

```bash
vault kv put course-tools/premium-enrollment \
  api_key="course-premium-demo-key-2026"
```

Runtime Vault API path used by RAR and the application:

```text
course-tools/data/premium-enrollment
```

## Step 9.3 — Verify as administrator

```bash
vault read course-tools/data/premium-enrollment
```

Do not print real production secrets in shared logs. This is a local demo value.

## Why setup and runtime commands differ

Setup may use the administrator token and `vault kv put`.

Runtime uses the IBM Verify delegated JWT directly and calls the exact KV v2 API path authorized by RAR.

```text
Setup:   admin token      → write secret
Runtime: delegated JWT    → read exact secret path
```

## STOP CHECKPOINT

```text
[ ] course-tools KV v2 mount exists
[ ] premium-enrollment secret exists
[ ] api_key field exists
[ ] value matches PREMIUM_API_EXPECTED_KEY in the demo application
```
