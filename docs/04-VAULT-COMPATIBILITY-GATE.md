# 4. Vault Compatibility Gate — Run This First

This is a **hard prerequisite** for the API-key use case.

## Why this step exists

The demo needs:

1. Vault Enterprise native AI Agent Registry.
2. Vault OAuth Resource Server configuration.
3. Vault Identity entities/aliases.
4. KV v2 to store the Premium Tool API key.

A Vault cluster in PKI-only mode rejects API requests to secret-engine mounts other than PKI. Do not spend time configuring IBM Verify until you know the Vault cluster can run this use case.

## Step 4.1 — Export Vault bootstrap settings

```bash
export VAULT_ADDR="http://127.0.0.1:8200"
export VAULT_TOKEN="<bootstrap-admin-or-root-token>"
```

If using a namespace:

```bash
export VAULT_NAMESPACE="<namespace>"
```

## Step 4.2 — Run the included checker

```bash
bash vault/scripts/00_check_compatibility.sh
```

The script checks:

- Vault is reachable.
- Version information is available.
- OAuth Resource Server activation/configuration API is reachable.
- Agent Registry API is reachable.
- A temporary KV v2 mount can be enabled and removed.

## Expected result

```text
PASS: Vault reachable
PASS: OAuth Resource Server API available
PASS: Agent Registry API available
PASS: KV v2 mount permitted
READY: This cluster can run the API-key cookbook
```

## If KV fails

Do not continue with this API-key cookbook on that cluster.

For a PKI-only cluster, use a different Vault Enterprise environment where KV secrets are permitted, or design a separate PKI-specific use case. The main cookbook intentionally stays focused on the simple tool-API-key scenario.

## If Agent Registry fails

Verify:

- Vault Enterprise version is 2.0.3 or later.
- The appropriate Enterprise entitlement is active.
- The namespace is correct.
- The bootstrap token has permission to access the endpoint.

## STOP CHECKPOINT

Proceed only when all required checks pass.
