<!--
Copyright IBM Corp. All Rights Reserved.

SPDX-License-Identifier: Apache-2.0
-->

# 5. Configure Vault trust, ACL and registration ceiling

**Purpose:** establish JWT validation, create the demo credential and both permission policies, and issue a restricted provisioning token. Skipping any of these leaves synchronization or runtime authorization incomplete.

| Configuration | Why it is needed |
|---|---|
| Verify OAuth discovery/JWKS | Identify the issuer and signing keys Vault will trust |
| OAuth Resource Server profile | Validate the runtime JWT and require RAR |
| `course-tool-subject` ACL | Grant the agent-subject access to the exact credential path |
| `course-tool-ceiling` | Bound the registered actor's maximum authority |
| `verify-agent-sync`/`uc3-sync` provisioning policy | Allow the receiver to manage identities and registration without secret-read access |
| KV v2 credential | Give the authorized read a real dummy value to retrieve |

## 5.1 Discover the issuer metadata

```bash
cd "$UC3_ROOT"
source lab.env
curl --fail-with-body -sS "$VERIFY_ISSUER/.well-known/openid-configuration" \
 -o .runtime/verify-discovery.json
jq -e --arg issuer "$VERIFY_ISSUER" '.issuer == $issuer and (.jwks_uri|type=="string")' \
 .runtime/verify-discovery.json
export VERIFY_JWKS_URI="$(jq -er '.jwks_uri' .runtime/verify-discovery.json)"
export VERIFY_TOKEN_URL="$(jq -er '.token_endpoint' .runtime/verify-discovery.json)"
printf 'Issuer=%s\nJWKS=%s\n' "$VERIFY_ISSUER" "$VERIFY_JWKS_URI"
curl --fail-with-body -sS "$VERIFY_JWKS_URI" -o .runtime/verify-jwks.json
jq -e '.keys|length>0' .runtime/verify-jwks.json
```

**Expected:** both checks print `true`. If discovery reports another issuer, correct `VERIFY_ISSUER` in `lab.env` and repeat; do not replace the returned signing-key URL with a guessed URL. If the discovered token endpoint differs from `lab.env`, set `VERIFY_TOKEN_URL` to that returned value in `lab.env`.

## 5.2 Run the dedicated-lab bootstrap

```bash
bash vault/scripts/11_bootstrap_agent_subject_lab.sh
```

The script activates OAuth Resource Server, creates `course-verify`, enables KV v2 at `course-tools/`, stores the dummy key at `course-tools/data/premium-enrollment`, writes the ACL and ceiling, and creates an eight-hour sync token. It does not create an agent or human entity.

**Expected:** successful completion and a printed `VAULT_MOUNT_ACCESSOR`. A feature activation 404, invalid license or unsupported API is a blocking compatibility failure. Check that the request reaches the intended Enterprise binary and that the license includes these capabilities.

## 5.3 Record the binding and restricted token

```bash
export VAULT_SYNC_TOKEN="$(cat .uc3-sync-token)"
curl --fail-with-body -sS -H "X-Vault-Token: $VAULT_ADMIN_TOKEN" \
 "$VAULT_ADDR/v1/sys/config/oauth-resource-server/$VAULT_PROFILE" \
 -o .runtime/vault-profile.json
export VAULT_MOUNT_ACCESSOR="$(jq -er '.data.mount_accessor //
 ("oauth-resource-server_root_" + .data.config_id)' .runtime/vault-profile.json)"
printf 'VAULT_MOUNT_ACCESSOR=%s\n' "$VAULT_MOUNT_ACCESSOR"
jq -e --arg issuer "$VERIFY_ISSUER" '.data | .issuer_id==$issuer and .enabled==true and
 .user_claim=="sub" and .optional_authorization_details==false' .runtime/vault-profile.json
```

**Expected:** `true`. Copy the accessor value into your notes for Step 7. The synthesized fallback applies to the root namespace used here. The alias is created with issuer and external ID; Vault derives the matching accessor.

## 5.4 Verify both policies and the restricted credential

```bash
for policy in course-tool-subject course-tool-ceiling; do
 curl --fail-with-body -sS -H "X-Vault-Token: $VAULT_ADMIN_TOKEN" \
  "$VAULT_ADDR/v1/sys/policies/acl/$policy" | jq '.data | {name,policy}'
done
curl --fail-with-body -sS -H "X-Vault-Token: $VAULT_SYNC_TOKEN" \
 "$VAULT_ADDR/v1/auth/token/lookup-self" -o .runtime/sync-token-check.json
jq -e '(.data.policies|index("uc3-sync")!=null) and
 (.data.policies|index("root")==null) and .data.ttl>0' .runtime/sync-token-check.json
```

**Expected:** each policy grants only `read` on `course-tools/data/premium-enrollment`, and the sync-token check prints `true`. Protect `.uc3-sync-token`; it can provision identities even though it cannot read the credential. Its eight-hour lifetime limits the lab session; if it expires, issue a fresh restricted token and re-render/restart the receiver configuration.

**Stop checkpoint:** trust profile enabled, issuer/JWKS correct, policies stored and restricted token valid. Continue to Step 6.
