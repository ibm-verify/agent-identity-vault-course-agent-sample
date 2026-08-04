# 12. Negative Tests — Prove the Controls Are Real

A strong demo shows at least one success and one intentional denial.

## Test 1 — Agent Registry enforcement

### Goal

Prove that Vault Agent Registry participates in runtime authorization.

### Action

Temporarily remove the Course Assistant Agent Registry registration, or use the lifecycle sync to suspend/deprovision it according to your policy.

The helper scripts include a lookup/validation path; destructive removal should be done only in a disposable demo environment.

### Run premium enrollment again

Expected:

```text
Human login                    SUCCESS
Actor token                    SUCCESS
IBM Verify token exchange      SUCCESS
Vault identity resolution      reaches actor
Vault Agent Registry check     FAIL
Secret returned                NO
Premium enrollment             FAILED
```


Restore/resynchronize the agent before continuing.

## Test 2 — Wrong tool API key

### Goal

Prove the credential used by the tool truly comes from Vault.

### Action

Change only the value in Vault:

```bash
bash vault/scripts/09_store_invalid_tool_secret.sh
```

The protected Course API still expects:

```text
course-premium-demo-key-2026
```

Vault now returns:

```text
intentionally-wrong-premium-key
```

### Run premium enrollment

Expected:

```text
IBM Verify token exchange      SUCCESS
Vault authorization            SUCCESS
Vault secret read              SUCCESS
Protected Premium Tool         HTTP 403
Premium enrollment             FAILED
```

Standard course enrollment should still succeed.


### Restore

```bash
bash vault/scripts/07_store_matching_tool_secret.sh
```

Premium enrollment should succeed again.

## Test 3 — Wrong RAR path

Request:

```json
{
  "type": "vault:path_access",
  "path": "course-tools/data/not-authorized",
  "capabilities": ["read"]
}
```

Expected: Vault denies access to the premium secret path.

## Test 4 — Wrong audience

Issue/use a JWT whose `aud` does not match `vault-course-tools`.

Expected: Vault rejects the JWT before secret authorization.

## Test 5 — Actor mismatch

Use an actor token that does not satisfy the subject's `may_act` relationship.

Expected: IBM Verify rejects the token exchange.

## Control matrix

| Test | IBM Verify | Vault auth | Secret read | Tool | Expected |
|---|---|---|---|---|---|
| Standard course | Login only | N/A | N/A | Normal path | Success |
| Premium / valid | Success | Success | Success | 200 | Success |
| Agent unregistered | Success | Deny | No | Not called | Fail |
| Wrong Vault secret | Success | Success | Success | 403 | Fail |
| Wrong RAR | Success | Deny | No | Not called | Fail |
| Wrong audience | Success | JWT reject | No | Not called | Fail |
| Wrong actor | Token exchange deny | N/A | No | Not called | Fail |
