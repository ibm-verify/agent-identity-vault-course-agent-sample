#!/usr/bin/env bash

# Copyright IBM Corp. All Rights Reserved.
# #
# SPDX-License-Identifier: Apache-2.0

set -eo pipefail
ENV_FILE="${ANTENNA_ENV_FILE:-scripts/00_env.local.sh}"
[[ -f "$ENV_FILE" ]] || ENV_FILE="scripts/00_env.sh"
source "$ENV_FILE"

if [[ -z "${VAULT_ADDR_HOST:-}" ]]; then
  echo "VAULT_ADDR_HOST is empty. Check scripts/00_env.sh"
  exit 1
fi
if [[ -z "${VAULT_TOKEN:-}" ]]; then
  echo "VAULT_TOKEN is empty. Check scripts/00_env.sh"
  exit 1
fi

NS_ARGS=()
if [[ -n "${VAULT_NAMESPACE:-}" ]]; then
  NS_ARGS=(-H "X-Vault-Namespace: ${VAULT_NAMESPACE}")
fi

echo "VAULT_ADDR_HOST=${VAULT_ADDR_HOST}"
echo

echo "List Vault Agent Registry records:"
curl -sS -H "X-Vault-Token: ${VAULT_TOKEN}" "${NS_ARGS[@]}" "${VAULT_ADDR_HOST}/v1/agent-registry/registration/display-name?list=true" | python3 -m json.tool || true

echo
echo "Read expected test record by display name: Agent for UC1"
curl -sS -H "X-Vault-Token: ${VAULT_TOKEN}" "${NS_ARGS[@]}" "${VAULT_ADDR_HOST}/v1/agent-registry/registration/display-name/Agent%20for%20UC1" | python3 -m json.tool || true

echo
echo "Read real password reset record by display name: Agent for password reset"
curl -sS -H "X-Vault-Token: ${VAULT_TOKEN}" "${NS_ARGS[@]}" "${VAULT_ADDR_HOST}/v1/agent-registry/registration/display-name/Agent%20for%20password%20reset" | python3 -m json.tool || true

echo
echo "Read expected test entity:"
curl -sS -H "X-Vault-Token: ${VAULT_TOKEN}" "${NS_ARGS[@]}" "${VAULT_ADDR_HOST}/v1/identity/entity/name/verify-agent-agent-uc1-001" | python3 -m json.tool || true

echo
echo "Read real password reset entity:"
curl -sS -H "X-Vault-Token: ${VAULT_TOKEN}" "${NS_ARGS[@]}" "${VAULT_ADDR_HOST}/v1/identity/entity/name/verify-agent-7200d406-3fdc-4523-b667-15182e4e52ed" | python3 -m json.tool || true
