#!/usr/bin/env bash

# Copyright IBM Corp. All Rights Reserved.
# #
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail
: "${VERIFY_TOKEN_URL:?source verify/scripts/00_env.sh first}"
: "${TOKEN_EXCHANGE_CLIENT_ID:?}"
: "${TOKEN_EXCHANGE_CLIENT_SECRET:?}"
: "${SUBJECT_TOKEN:?export SUBJECT_TOKEN first}"
: "${ACTOR_TOKEN:?export ACTOR_TOKEN first}"
: "${VAULT_SECRET_API_PATH:=course-tools/data/premium-enrollment}"
DETAILS=$(jq -nc --arg path "$VAULT_SECRET_API_PATH" '[{type:"vault:path_access",path:$path,capabilities:["read"]}]')
RESP=$(curl -sS --fail -X POST "$VERIFY_TOKEN_URL" \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  --data-urlencode 'grant_type=urn:ietf:params:oauth:grant-type:token-exchange' \
  --data-urlencode "client_id=$TOKEN_EXCHANGE_CLIENT_ID" \
  --data-urlencode "client_secret=$TOKEN_EXCHANGE_CLIENT_SECRET" \
  --data-urlencode "subject_token=$SUBJECT_TOKEN" \
  --data-urlencode 'subject_token_type=urn:ietf:params:oauth:token-type:access_token' \
  --data-urlencode "actor_token=$ACTOR_TOKEN" \
  --data-urlencode 'actor_token_type=urn:ietf:params:oauth:token-type:access_token' \
  --data-urlencode 'requested_token_type=urn:ietf:params:oauth:token-type:access_token' \
  --data-urlencode "authorization_details=$DETAILS")
export DELEGATED_TOKEN=$(printf '%s' "$RESP" | jq -r '.access_token')
[[ -n "$DELEGATED_TOKEN" && "$DELEGATED_TOKEN" != "null" ]] || { echo "$RESP" | jq .; exit 1; }
printf 'Delegated token obtained. Safe claims:\n'
"$(dirname "$0")/02_decode_jwt.sh" "$DELEGATED_TOKEN"
printf '%s\n' "$DELEGATED_TOKEN" > /tmp/course-demo-delegated.token
