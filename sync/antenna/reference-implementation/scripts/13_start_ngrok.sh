#!/usr/bin/env bash

# Copyright IBM Corp. All Rights Reserved.
# #
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail
ENV_FILE="${ANTENNA_ENV_FILE:-scripts/00_env.local.sh}"
[[ -f "$ENV_FILE" ]] || ENV_FILE="scripts/00_env.sh"
source "$ENV_FILE"

if ! command -v ngrok >/dev/null 2>&1; then
  echo "ngrok is not installed. On Mac: brew install ngrok"
  exit 1
fi

echo "Starting ngrok for Antenna transmitter on local HTTPS port ${TX_PORT}."
echo "Copy the Forwarding https://... URL into scripts/00_env.sh as NGROK_URL."
echo "Then rerun scripts/03_render_templates.sh and scripts/04_start_lab.sh."
echo
ngrok http "https://localhost:${TX_PORT}"
