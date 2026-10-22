<!--
Copyright IBM Corp. All Rights Reserved.

SPDX-License-Identifier: Apache-2.0
-->

# 4. Start and check Vault Enterprise

**Purpose:** start a disposable licensed server that both the host and Antenna receiver can reach. This guide uses the **root namespace**; `VAULT_NAMESPACE` is empty and no `X-Vault-Namespace` header is sent. Root namespace and root-token authentication are different concepts.

## 4.1 Start the server — Terminal A

Open a new terminal and set the actual absolute license path:

```bash
export VAULT_LICENSE_PATH='/absolute/path/to/vault.hclic'
vault server -dev -dev-root-token-id=root -dev-listen-address=0.0.0.0:8200
```

**Expected:** Vault starts, is initialized and unsealed, and listens on port 8200. Leave this terminal running. If license validation or feature entitlement fails, correct the license/build before continuing.

The listener binds all host interfaces so Docker can reach it. Run this disposable configuration only on an isolated workstation with access to port 8200 restricted. Dev mode keeps its state in memory. Stopping this server discards its configuration and secrets; the guide does not configure raft storage.

## 4.2 Check from Terminal B

```bash
cd "$UC3_ROOT"
source lab.env
curl --fail-with-body -sS "$VAULT_ADDR/v1/sys/health" -o .runtime/vault-health.json
jq -e '.initialized == true and .sealed == false' .runtime/vault-health.json
jq '{version,initialized,sealed}' .runtime/vault-health.json
```

**Expected:** `true`, with your actual Enterprise version. HTTP connection failure means the server/listener is not ready. Do not continue until this check passes.

## 4.3 Check administrator access

```bash
curl --fail-with-body -sS -H "X-Vault-Token: $VAULT_ADMIN_TOKEN" \
 "$VAULT_ADDR/v1/auth/token/lookup-self" -o .runtime/vault-admin-check.json
jq -e '.data.policies | index("root") != null' .runtime/vault-admin-check.json
```

**Expected:** `true` for this new dedicated dev server. The admin credential is used only for setup and inspection. Synchronization will receive a separate restricted token; runtime reads will use a Verify-issued JWT.

**Stop checkpoint:** health and admin checks pass. Proceed to Step 5.
