#!/usr/bin/env bash

# Copyright IBM Corp. All Rights Reserved.
# #
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail
: "${VERIFY_TENANT_HOST:?}"
: "${VERIFY_MGMT_TOKEN:?run 04_get_management_token.sh first}"
DIR=$(cd "$(dirname "$0")/.." && pwd)
curl -sS --fail -X POST "https://${VERIFY_TENANT_HOST}/oidc-mgmt/v1.0/auth-detail-types" \
  -H "Authorization: Bearer ${VERIFY_MGMT_TOKEN}" \
  -H 'Content-Type: application/json' \
  --data @"${DIR}/adt/vault-path-access.create-payload.json" | jq .
