#!/usr/bin/env bash

# Copyright IBM Corp. All Rights Reserved.
# #
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail

DIR=$(cd "$(dirname "$0")" && pwd)
source "$DIR/_common.sh"

: "${VAULT_SYNC_TOKEN:?export VAULT_SYNC_TOKEN}"
: "${VAULT_AGENT_ENTITY_ID:?export VAULT_AGENT_ENTITY_ID after sync}"

CURL_ARGS=(
  -sS
  --fail
  -H "X-Vault-Token: $VAULT_SYNC_TOKEN"
)

if [[ -n "${VAULT_NAMESPACE:-}" ]]; then
  CURL_ARGS+=(
    -H "X-Vault-Namespace: $VAULT_NAMESPACE"
  )
fi

echo 'Agent Registry record:'

curl "${CURL_ARGS[@]}" \
  "$VAULT_ADDR/v1/agent-registry/registration/entity-id/$VAULT_AGENT_ENTITY_ID" |
jq .

echo 'Entity:'

curl "${CURL_ARGS[@]}" \
  "$VAULT_ADDR/v1/identity/entity/id/$VAULT_AGENT_ENTITY_ID" |
jq .