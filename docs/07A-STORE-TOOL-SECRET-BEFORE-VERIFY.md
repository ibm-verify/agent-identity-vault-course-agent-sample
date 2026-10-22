<!--
Copyright IBM Corp. All Rights Reserved.

SPDX-License-Identifier: Apache-2.0
-->

# 7A. Check the stored credential before token issuance

**Purpose:** prove the secret exists and matches the protected API's configured dummy value. This isolates secret storage from later JWT authorization failures.

Step 5 created the credential. Inspect it without displaying the key:

```bash
cd "$UC3_ROOT"
curl --fail-with-body -sS -H "X-Vault-Token: $VAULT_ADMIN_TOKEN" \
 "$VAULT_ADDR/v1/course-tools/data/premium-enrollment" -o .runtime/admin-secret-check.json
jq -e --arg key "$PREMIUM_API_EXPECTED_KEY" '.data.data.api_key==$key' \
 .runtime/admin-secret-check.json
rm .runtime/admin-secret-check.json
```

**Expected:** `true`. HTTP 404 means the mount or secret was not created; return to Step 5. A key mismatch must be fixed before continuing.

KV v2 has two related paths: CLI path `course-tools/premium-enrollment` and API/ACL/RAR path `course-tools/data/premium-enrollment`. Runtime authorization uses the API path including `/data/`.

**Stop checkpoint:** administrator read and expected-value comparison pass. Continue to Step 8.
