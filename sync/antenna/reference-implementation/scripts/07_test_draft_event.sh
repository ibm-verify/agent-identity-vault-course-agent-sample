#!/usr/bin/env bash

# Copyright IBM Corp. All Rights Reserved.
# #
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail
ENV_FILE="${ANTENNA_ENV_FILE:-scripts/00_env.local.sh}"
[[ -f "$ENV_FILE" ]] || ENV_FILE="scripts/00_env.sh"
source "$ENV_FILE"

curl -sk -i -X POST "https://${HOST_IP}:${TX_PORT}/sources/push_src_1/events" \
  -H "Content-Type: application/json" \
  --data-binary @examples/draft_agent_event.json

echo

echo "Sent DRAFT test. Expected: no Vault Agent Registry create; delete/no-op in receiver logs."
