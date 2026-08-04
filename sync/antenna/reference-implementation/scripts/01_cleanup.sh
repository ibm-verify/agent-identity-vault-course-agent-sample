#!/usr/bin/env bash

# Copyright IBM Corp. All Rights Reserved.
# #
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail
ENV_FILE="${ANTENNA_ENV_FILE:-scripts/00_env.local.sh}"
[[ -f "$ENV_FILE" ]] || ENV_FILE="scripts/00_env.sh"
source "$ENV_FILE"

docker compose down --remove-orphans || true
rm -rf db-tx db-rx deploying
mkdir -p db-tx db-rx
chmod -R 777 db-tx db-rx

echo "Cleaned old containers and SQLite DB folders."
