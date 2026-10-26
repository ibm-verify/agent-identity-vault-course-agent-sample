#!/usr/bin/env bash
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail
: "${VAULT_ADMIN_TOKEN:=${VAULT_TOKEN:-}}"
: "${VAULT_ADDR:?}" "${VAULT_ADMIN_TOKEN:?}" "${VERIFY_AGENT_ID:?}" "${VERIFY_ISSUER:?}"
headers=(-H "X-Vault-Token: $VAULT_ADMIN_TOKEN")
if [[ -n ${VAULT_NAMESPACE:-} ]]; then headers+=(-H "X-Vault-Namespace: $VAULT_NAMESPACE"); fi
work=$(mktemp -d); trap 'rm -rf "$work"' EXIT
curl --fail-with-body -sS "${headers[@]}" "$VAULT_ADDR/v1/identity/entity/name/verify-agent-$VERIFY_AGENT_ID" > "$work/entity"
jq -e '.data | .disabled==false and (.policies|index("course-tool-subject")!=null)' "$work/entity" >/dev/null || { echo 'FAIL: entity disabled or course-tool-subject ACL missing' >&2; exit 1; }
alias_id=$(jq -er --arg agent "$VERIFY_AGENT_ID" '[.data.aliases[]? | select(.name==$agent)] | if length==1 then .[0].id else error("Expected exactly one AgentID alias") end' "$work/entity")
# Entity alias summaries can omit issuer/external_id. Read the alias object itself.
curl --fail-with-body -sS "${headers[@]}" "$VAULT_ADDR/v1/identity/entity-alias/id/$alias_id" > "$work/alias"
jq -e --arg agent "$VERIFY_AGENT_ID" --arg issuer "$VERIFY_ISSUER" --arg entity "$(jq -er '.data.id' "$work/entity")" '.data | .name==$agent and .external_id==$agent and .issuer==$issuer and .canonical_id==$entity' "$work/alias" >/dev/null || { echo 'FAIL: issuer-bound AgentID alias mismatch' >&2; exit 1; }
entity=$(jq -er '.data.id' "$work/entity")
curl --fail-with-body -sS "${headers[@]}" "$VAULT_ADDR/v1/agent-registry/registration/entity-id/$entity" > "$work/reg"
jq -e --arg entity "$entity" '.data | .entity_id==$entity and .optional_authorization_details==false and (.ceiling_policies|index("course-tool-ceiling")!=null)' "$work/reg" >/dev/null || { echo 'FAIL: registration entity, ceiling or RAR setting mismatch' >&2; exit 1; }
printf 'PASS: enabled agent, permanent issuer-bound alias, ACL, registration and ceiling. Entity=%s\n' "$entity"
