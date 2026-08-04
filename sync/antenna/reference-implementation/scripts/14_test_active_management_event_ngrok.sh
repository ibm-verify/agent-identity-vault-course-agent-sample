#!/usr/bin/env bash

# Copyright IBM Corp. All Rights Reserved.
# #
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail
ENV_FILE="${ANTENNA_ENV_FILE:-scripts/00_env.local.sh}"
[[ -f "$ENV_FILE" ]] || ENV_FILE="scripts/00_env.sh"
source "$ENV_FILE"

if [[ -z "${NGROK_URL:-}" || "${NGROK_URL}" == "CHANGEME_NGROK_HTTPS_URL" ]]; then
  echo "Set NGROK_URL in scripts/00_env.sh first."
  exit 1
fi

curl -sk -i -X POST "${NGROK_URL}/sources/push_src_1/events" \
  -H "Content-Type: application/json" \
  -H "ngrok-skip-browser-warning: true" \
  --data-binary @examples/active_management_event_verify_agent.json

echo

echo "Sent ACTIVE IBM Verify management event through ngrok. Expected: Vault entity + aliases + Vault Agent Registry record created/updated."
