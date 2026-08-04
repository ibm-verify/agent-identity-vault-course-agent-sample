#!/usr/bin/env bash

# Copyright IBM Corp. All Rights Reserved.
# #
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail
: "${VAULT_ADDR:?}"
: "${DELEGATED_TOKEN:?export DELEGATED_TOKEN}"
PATH_API="${VAULT_SECRET_API_PATH:-course-tools/data/premium-enrollment}"
ARGS=(-H "X-Vault-Token: $DELEGATED_TOKEN")
[[ -n "${VAULT_NAMESPACE:-}" ]] && ARGS+=( -H "X-Vault-Namespace: $VAULT_NAMESPACE" )
curl -sS --fail "${ARGS[@]}" "$VAULT_ADDR/v1/$PATH_API" | jq '{data:{data:(.data.data|with_entries(.value="<redacted>")),metadata:.data.metadata}}'
