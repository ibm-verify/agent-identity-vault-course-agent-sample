#!/usr/bin/env bash
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0

# Run only against the dedicated UC3 lab; does not create agent identities.
set -euo pipefail
umask 077
: "${VAULT_ADMIN_TOKEN:=${VAULT_TOKEN:-}}"
: "${VAULT_ADDR:?}" "${VAULT_ADMIN_TOKEN:?}" "${VERIFY_ISSUER:?}" "${VERIFY_JWKS_URI:?}" "${PREMIUM_API_EXPECTED_KEY:?}"
VAULT_PROFILE=${VAULT_PROFILE:-course-verify}
headers=(-H "X-Vault-Token: $VAULT_ADMIN_TOKEN" -H 'Content-Type: application/json')
if [[ -n ${VAULT_NAMESPACE:-} ]]; then headers+=(-H "X-Vault-Namespace: $VAULT_NAMESPACE"); fi
api() { curl --fail-with-body -sS "${headers[@]}" "$@"; }
api -X POST "$VAULT_ADDR/v1/sys/activation-flags/oauth-resource-server/activate" > /dev/null
work=$(mktemp -d); trap 'rm -rf "$work"' EXIT
jq -n --arg issuer "$VERIFY_ISSUER" --arg jwks "$VERIFY_JWKS_URI" '{issuer_id:$issuer,use_jwks:true,jwks_uri:$jwks,user_claim:"sub",supported_algorithms:["RS256"],jwt_type:"access_token",no_default_policy:true,optional_authorization_details:false,enabled:true}' > "$work/profile.json"
# A dedicated profile is required. Reuse only after inspecting the same issuer/binding.
api -X POST --data-binary @"$work/profile.json" "$VAULT_ADDR/v1/sys/config/oauth-resource-server/$VAULT_PROFILE" > /dev/null
api "$VAULT_ADDR/v1/sys/config/oauth-resource-server/$VAULT_PROFILE" > "$work/profile-read.json"
accessor=$(jq -r '.data.mount_accessor // empty' "$work/profile-read.json")
if [[ -z $accessor && -z ${VAULT_NAMESPACE:-} ]]; then accessor="oauth-resource-server_root_$(jq -er '.data.config_id' "$work/profile-read.json")"; fi
[[ -n $accessor ]] || { echo 'Non-root namespace: obtain the actual profile mount_accessor before continuing'; exit 1; }
api "$VAULT_ADDR/v1/sys/mounts" > "$work/mounts.json"
if ! jq -e '.data["course-tools/"]' "$work/mounts.json" >/dev/null; then
 api -X POST --data '{"type":"kv","options":{"version":"2"}}' "$VAULT_ADDR/v1/sys/mounts/course-tools" > /dev/null
else
 jq -e '.data["course-tools/"] | .type=="kv" and .options.version=="2"' "$work/mounts.json" >/dev/null
fi
jq -n --arg key "$PREMIUM_API_EXPECTED_KEY" '{data:{api_key:$key}}' > "$work/secret.json"
api -X POST --data-binary @"$work/secret.json" "$VAULT_ADDR/v1/course-tools/data/premium-enrollment" > /dev/null
printf 'path "course-tools/data/premium-enrollment" { capabilities = ["read"] }\n' > "$work/read.hcl"
jq -n --rawfile policy "$work/read.hcl" '{policy:$policy}' > "$work/policy.json"
for policy in course-tool-subject course-tool-ceiling; do
 api -X PUT --data-binary @"$work/policy.json" "$VAULT_ADDR/v1/sys/policies/acl/$policy" > /dev/null
done
cat > "$work/sync.hcl" <<'HCL'
path "auth/token/lookup-self" { capabilities = ["read"] }
path "identity/entity" { capabilities = ["create", "update"] }
path "identity/entity/name/*" { capabilities = ["read"] }
path "identity/entity/id/*" { capabilities = ["read", "update"] }
path "identity/lookup/entity" { capabilities = ["update"] }
path "identity/entity-alias" { capabilities = ["create", "update"] }
path "identity/entity-alias/id/*" { capabilities = ["read"] }
path "agent-registry/register" { capabilities = ["create", "update"] }
path "agent-registry/registration/entity-id/*" { capabilities = ["read"] }
path "agent-registry/registration/id/*" { capabilities = ["read", "update", "delete"] }
HCL
jq -n --rawfile policy "$work/sync.hcl" '{policy:$policy}' > "$work/sync.json"
api -X PUT --data-binary @"$work/sync.json" "$VAULT_ADDR/v1/sys/policies/acl/uc3-sync" > /dev/null
api -X POST --data '{"policies":["uc3-sync"],"no_default_policy":true,"ttl":"8h","renewable":true}' "$VAULT_ADDR/v1/auth/token/create" > "$work/token.json"
jq -er '.auth.client_token' "$work/token.json" > .uc3-sync-token
chmod 600 .uc3-sync-token
printf 'VAULT_MOUNT_ACCESSOR=%s\nRestricted token saved in .uc3-sync-token (8-hour TTL).\n' "$accessor"
