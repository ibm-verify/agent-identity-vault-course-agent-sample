# 7A. Validate the New Vault License and Store the API Key(Optional)(Not Required if no license change)

Complete this checkpoint **after the agent alias and Agent Registry synchronization work and before starting IBM Verify Guide 8**.

## What this proves

1. The replacement Vault Enterprise license is active.
2. The cluster is no longer restricted to PKI-only secret engines.
3. KV v2 can store the Premium Enrollment Tool API key.
4. Vault can return the stored value to an administrator.

This is only a bootstrap/admin validation. Retrieval with an IBM Verify delegated JWT is tested later, after Guide 8 creates the subject, actor, RAR, and token-exchange configuration.

## Step 7A.1 — Prepare the Vault CLI

From the cookbook root:

```bash
export PATH="$HOME/Downloads/vault_2.0.3+ent_darwin_arm64:$PATH"
export VAULT_ADDR="http://127.0.0.1:8200"
export VAULT_TOKEN="root"
export VAULT_NAMESPACE=""

which vault
vault version
vault status
```

Use your real bootstrap token if it is not `root`. Do not put that token in a checked-in file.

## Step 7A.2 — Apply or confirm the replacement license

If the team gave you a license file and it has not yet been applied:

```bash
vault write sys/license text=@/absolute/path/to/vault.hclic
```

Then check license status:

```bash
vault read sys/license/status
```

If Vault was started with a license environment variable or configuration-file path instead of the `sys/license` endpoint, stop and restart that same Vault process using the new license source, then rerun `vault status` and the compatibility gate below. Do not start a second Vault server against the same storage.

## Step 7A.3 — Rerun the complete compatibility gate

```bash
bash vault/scripts/00_check_compatibility.sh
```

Required result:

```text
PASS: Vault reachable
PASS: OAuth Resource Server capability available/activated
PASS: Agent Registry API available
PASS: KV v2 secret engine is permitted
READY: This Vault environment can proceed with the API-key course-agent cookbook.
```

The script creates and removes a uniquely named temporary KV mount. It does not touch the synchronized agent alias or Agent Registry record.

## Step 7A.4 — Confirm synchronization still exists

Applying a license should not replace the Vault data store. Confirm the alias and agent registration still exist:

```bash
export VAULT_TOKEN="$VAULT_SYNC_TOKEN"
bash vault/scripts/05_validate_synced_agent.sh
```

If `VAULT_SYNC_TOKEN` is unavailable, use the bootstrap token only for this check, then return to the restricted token model.

## Step 7A.5 — Enable the KV v2 mount

Restore the bootstrap token, then enable the permanent demo mount:

```bash
export VAULT_TOKEN="root"
bash vault/scripts/06_enable_kv.sh
```

Verify:

```bash
vault secrets list -detailed | grep -A3 '^course-tools/'
```

Expected mount:

```text
course-tools/    kv    version=2
```

## Step 7A.6 — Store the matching demo API key

```bash
bash vault/scripts/07_store_matching_tool_secret.sh
```

The script stores:

```text
Logical path: course-tools/premium-enrollment
API path:     course-tools/data/premium-enrollment
Field:        api_key
Demo value:   course-premium-demo-key-2026
```

## Step 7A.7 — Prove administrator retrieval

Prefer a redacted metadata check for screenshots and shared terminals:

```bash
vault kv get -format=json course-tools/premium-enrollment \
  | jq '{created_time:.data.metadata.created_time, fields:(.data.data|keys)}'
```

Expected field list:

```json
{
  "fields": ["api_key"]
}
```

For a local one-time equality test without printing the key:

```bash
test "$(vault kv get -field=api_key course-tools/premium-enrollment)" = \
  "course-premium-demo-key-2026" \
  && echo "PASS: stored API key matches the demo tool" \
  || echo "FAIL: stored API key does not match"
```

## What is not yet proven

Do not run `vault/scripts/08_read_secret_with_delegated_jwt.sh` yet. It needs `DELEGATED_TOKEN`, which is created only after Guide 8 configures IBM Verify OBO and token exchange.

## STOP CHECKPOINT

```text
[ ] New non-PKI license active
[ ] Complete compatibility gate passes
[ ] Existing synchronized agent alias still exists
[ ] Existing Agent Registry registration still exists
[ ] course-tools/ KV v2 mount exists
[ ] api_key field exists at course-tools/premium-enrollment
[ ] Local equality check passes without printing the secret
```

Continue only now to [08-CONFIGURE-VERIFY-OBO.md](08-CONFIGURE-VERIFY-OBO.md).
