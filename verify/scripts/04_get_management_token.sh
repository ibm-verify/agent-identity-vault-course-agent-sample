#!/usr/bin/env bash
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail
umask 077
: "${VERIFY_TOKEN_URL:?}" "${VERIFY_CLIENT_ID:?}" "${VERIFY_CLIENT_SECRET:?}"
mkdir -p .runtime
curl --fail-with-body -sS -X POST "$VERIFY_TOKEN_URL" -H 'Content-Type: application/x-www-form-urlencoded' \
 --data-urlencode grant_type=client_credentials --data-urlencode "client_id=$VERIFY_CLIENT_ID" \
 --data-urlencode "client_secret=$VERIFY_CLIENT_SECRET" -o .runtime/verify-management-token.json
jq -e '.access_token|type=="string" and length>0' .runtime/verify-management-token.json >/dev/null
echo 'PASS: management token saved privately; export VERIFY_MGMT_TOKEN from .runtime/verify-management-token.json in the calling shell'
