#!/usr/bin/env bash
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail
umask 077
: "${VERIFY_TOKEN_URL:?source lab.env first}" "${ACTOR_CLIENT_ID:?}" "${ACTOR_CLIENT_SECRET:?}"
mkdir -p .runtime
curl --fail-with-body -sS -X POST "$VERIFY_TOKEN_URL" -H 'Content-Type: application/x-www-form-urlencoded' \
 --data-urlencode grant_type=client_credentials --data-urlencode "client_id=$ACTOR_CLIENT_ID" \
 --data-urlencode "client_secret=$ACTOR_CLIENT_SECRET" -o .runtime/actor-response.json
jq -erj '.access_token' .runtime/actor-response.json > .runtime/actor.token
python3 "$(dirname "$0")/06_check_jwt_contract.py" actor .runtime/actor.token
