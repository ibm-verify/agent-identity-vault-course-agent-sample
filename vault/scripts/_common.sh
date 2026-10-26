#!/usr/bin/env bash

# Copyright IBM Corp. All Rights Reserved.
# #
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail
: "${VAULT_ADDR:?export VAULT_ADDR first}"
HEADER_ARGS=()
if [[ -n "${VAULT_NAMESPACE:-}" ]]; then HEADER_ARGS+=( -H "X-Vault-Namespace: ${VAULT_NAMESPACE}" ); fi
need_admin_token(){ : "${VAULT_TOKEN:=${VAULT_ADMIN_TOKEN:-}}"; : "${VAULT_TOKEN:?export VAULT_ADMIN_TOKEN first}"; export VAULT_TOKEN; }
