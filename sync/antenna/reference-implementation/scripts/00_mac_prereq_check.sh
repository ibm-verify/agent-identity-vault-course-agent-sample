#!/usr/bin/env bash

# Copyright IBM Corp. All Rights Reserved.
# #
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail

missing=0
for c in docker openssl curl python3; do
  if ! command -v "$c" >/dev/null 2>&1; then
    echo "Missing: $c"
    missing=1
  else
    echo "OK: $c -> $(command -v "$c")"
  fi
done

if docker compose version >/dev/null 2>&1; then
  echo "OK: docker compose -> $(docker compose version)"
else
  echo "Missing or not running: docker compose / Docker Desktop"
  missing=1
fi

if command -v envsubst >/dev/null 2>&1; then
  echo "OK: envsubst -> $(command -v envsubst)"
else
  echo "Missing: envsubst. On Mac install with: brew install gettext && brew link --force gettext"
  missing=1
fi

if command -v ngrok >/dev/null 2>&1; then
  echo "OK: ngrok -> $(ngrok version || true)"
else
  echo "Missing: ngrok. Install with: brew install ngrok"
fi

if [[ "$missing" -ne 0 ]]; then
  echo "Fix missing prerequisites and run again."
  exit 1
fi

echo "Prerequisite check complete."
