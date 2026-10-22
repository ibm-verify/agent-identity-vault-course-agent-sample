#!/usr/bin/env bash
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail
umask 077
: "${VAULT_ADDR:?}" "${VAULT_ADMIN_TOKEN:?}"
DIR=$(cd "$(dirname "$0")/.." && pwd)
work=$(mktemp -d); trap 'rm -rf "$work"' EXIT
jq -n --rawfile policy "$DIR/policies/verify-agent-sync.hcl" '{policy:$policy}' > "$work/policy.json"
curl --fail-with-body -sS -X PUT -H "X-Vault-Token: $VAULT_ADMIN_TOKEN" -H 'Content-Type: application/json' --data-binary @"$work/policy.json" "$VAULT_ADDR/v1/sys/policies/acl/uc3-sync" > /dev/null
curl --fail-with-body -sS -X POST -H "X-Vault-Token: $VAULT_ADMIN_TOKEN" -H 'Content-Type: application/json' --data '{"policies":["uc3-sync"],"no_default_policy":true,"ttl":"8h","renewable":true}' "$VAULT_ADDR/v1/auth/token/create" > "$work/token.json"
jq -erj '.auth.client_token' "$work/token.json" > .uc3-sync-token
chmod 600 .uc3-sync-token
echo 'PASS: restricted sync token saved privately to .uc3-sync-token (8h)'
