#!/usr/bin/env bash

# Copyright IBM Corp. All Rights Reserved.
# #
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail
: "${VERIFY_TOKEN_URL:?source verify/scripts/00_env.sh first}"
: "${ACTOR_CLIENT_ID:?}"
: "${ACTOR_CLIENT_SECRET:?}"
RESP=$(curl -sS --fail -X POST "$VERIFY_TOKEN_URL" \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  --data-urlencode 'grant_type=client_credentials' \
  --data-urlencode "client_id=$ACTOR_CLIENT_ID" \
  --data-urlencode "client_secret=$ACTOR_CLIENT_SECRET")
export ACTOR_TOKEN=$(printf '%s' "$RESP" | jq -r '.access_token')
if [[ -z "$ACTOR_TOKEN" || "$ACTOR_TOKEN" == "null" ]]; then
  echo "Actor token response did not contain access_token" >&2; exit 1
fi
printf 'Actor token obtained. Export in current shell with:\nexport ACTOR_TOKEN=%q\n' "$ACTOR_TOKEN"
printf '%s\n' "$ACTOR_TOKEN" > /tmp/course-demo-actor.token
printf 'Saved temporary token to /tmp/course-demo-actor.token (delete after demo).\n'
