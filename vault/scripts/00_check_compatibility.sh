#!/usr/bin/env bash

# Copyright IBM Corp. All Rights Reserved.
# #
# SPDX-License-Identifier: Apache-2.0

set -uo pipefail
DIR=$(cd "$(dirname "$0")" && pwd)
source "$DIR/_common.sh"
need_admin_token
fail=0
pass(){ printf 'PASS: %s\n' "$1"; }
warn(){ printf 'FAIL: %s\n' "$1" >&2; fail=1; }

echo '=== Vault compatibility gate ==='
if vault status >/dev/null 2>&1; then pass 'Vault reachable'; else warn 'Vault is not reachable/unsealed'; fi
vault version || true

# OAuth Resource Server is a system API. Activate or confirm activation.
if vault write -f sys/activation-flags/oauth-resource-server/activate >/tmp/course-demo-oauth-activate.out 2>/tmp/course-demo-oauth-activate.err; then
  pass 'OAuth Resource Server capability available/activated'
else
  warn "OAuth Resource Server activation failed: $(cat /tmp/course-demo-oauth-activate.err)"
fi

# Agent Registry endpoint should be callable in a compatible Enterprise environment.
code=$(curl -sS -o /tmp/course-demo-agent-registry.out -w '%{http_code}' \
  -H "X-Vault-Token: $VAULT_TOKEN" "${HEADER_ARGS[@]}" \
  "$VAULT_ADDR/v1/agent-registry/registration/display-name?list=true" || true)
if [[ "$code" =~ ^2 ]]; then
  pass 'Agent Registry API available'
else
  warn "Agent Registry API check returned HTTP $code. Response: $(cat /tmp/course-demo-agent-registry.out 2>/dev/null)"
fi

# Safe temporary KV mount check. PKI-only clusters reject this operation.
TMP_MOUNT="course-demo-compat-$$"
if vault secrets enable -path="$TMP_MOUNT" kv-v2 >/tmp/course-demo-kv.out 2>/tmp/course-demo-kv.err; then
  pass 'KV v2 secret engine is permitted'
  vault secrets disable "$TMP_MOUNT" >/dev/null 2>&1 || true
else
  warn "KV v2 is not permitted. This API-key cookbook cannot run on this cluster. Details: $(cat /tmp/course-demo-kv.err)"
fi

if [[ $fail -ne 0 ]]; then
  echo
  echo 'NOT READY: Fix the failed checks or use a Vault Enterprise environment that supports this use case.' >&2
  exit 1
fi

echo
echo 'READY: This Vault environment can proceed with the API-key course-agent cookbook.'
