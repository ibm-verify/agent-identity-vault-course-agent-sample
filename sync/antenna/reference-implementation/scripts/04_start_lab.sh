#!/usr/bin/env bash

# Copyright IBM Corp. All Rights Reserved.
# #
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail
ENV_FILE="${ANTENNA_ENV_FILE:-scripts/00_env.local.sh}"
[[ -f "$ENV_FILE" ]] || ENV_FILE="scripts/00_env.sh"
source "$ENV_FILE"

docker compose pull
docker compose up -d
sleep 45

docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}' | grep "${LAB_NAME}" || true

echo
echo "Validate transmitter metadata through ngrok after you start ngrok:"
echo "  curl -sk ${NGROK_URL}/.well-known/ssf-configuration | python3 -m json.tool"
echo
echo "Then create receiver stream:"
echo "  bash scripts/05_create_stream_json.sh && bash scripts/06_create_receiver_stream.sh"
