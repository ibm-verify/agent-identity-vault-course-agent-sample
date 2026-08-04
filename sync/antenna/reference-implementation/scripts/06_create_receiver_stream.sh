#!/usr/bin/env bash

# Copyright IBM Corp. All Rights Reserved.
# #
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail
ENV_FILE="${ANTENNA_ENV_FILE:-scripts/00_env.local.sh}"
[[ -f "$ENV_FILE" ]] || ENV_FILE="scripts/00_env.sh"
source "$ENV_FILE"

curl -sk -i -X POST "https://${HOST_IP}:${RX_PORT}/mgmt/v2.0/receivers/config" \
  -H "Content-Type: application/json" \
  --data-binary @create_stream_post_data.json

echo

echo "Receiver stream create call completed. Check receiver logs for stream poll."
