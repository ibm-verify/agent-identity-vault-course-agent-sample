#!/usr/bin/env bash
set -euo pipefail
DIR=$(cd "$(dirname "$0")" && pwd); source "$DIR/_common.sh"
: "${VAULT_SYNC_TOKEN:?export VAULT_SYNC_TOKEN}"
: "${VAULT_AGENT_ENTITY_ID:?export VAULT_AGENT_ENTITY_ID after sync}"
echo 'Agent Registry record:'
curl -sS --fail -H "X-Vault-Token: $VAULT_SYNC_TOKEN" "${HEADER_ARGS[@]}" \
  "$VAULT_ADDR/v1/agent-registry/registration/entity-id/$VAULT_AGENT_ENTITY_ID" | jq .
echo 'Entity:'
curl -sS --fail -H "X-Vault-Token: $VAULT_SYNC_TOKEN" "${HEADER_ARGS[@]}" \
  "$VAULT_ADDR/v1/identity/entity/id/$VAULT_AGENT_ENTITY_ID" | jq .
