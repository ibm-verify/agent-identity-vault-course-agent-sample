#!/usr/bin/env bash

# Copyright IBM Corp. All Rights Reserved.
# #
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail
: "${VERIFY_TOKEN_URL:?}"
: "${VERIFY_MGMT_CLIENT_ID:?}"
: "${VERIFY_MGMT_CLIENT_SECRET:?}"
RESP=$(curl -sS --fail -X POST "$VERIFY_TOKEN_URL" \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  --data-urlencode 'grant_type=client_credentials' \
  --data-urlencode "client_id=$VERIFY_MGMT_CLIENT_ID" \
  --data-urlencode "client_secret=$VERIFY_MGMT_CLIENT_SECRET")
export VERIFY_MGMT_TOKEN=$(printf '%s' "$RESP" | jq -r '.access_token')
printf 'Management token obtained for this shell.\n'
