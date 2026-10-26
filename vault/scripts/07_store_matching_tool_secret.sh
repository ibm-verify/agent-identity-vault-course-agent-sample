#!/usr/bin/env bash
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail
: "${VAULT_ADDR:?}" "${VAULT_ADMIN_TOKEN:?}" "${PREMIUM_API_EXPECTED_KEY:?}"
body=$(jq -nc --arg key "$PREMIUM_API_EXPECTED_KEY" '{data:{api_key:$key}}')
curl --fail-with-body -sS -X POST -H "X-Vault-Token: $VAULT_ADMIN_TOKEN" -H 'Content-Type: application/json' --data "$body" "$VAULT_ADDR/v1/course-tools/data/premium-enrollment" > /dev/null
echo 'PASS: expected dummy key stored'
