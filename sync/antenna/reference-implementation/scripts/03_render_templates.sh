#!/usr/bin/env bash

# Copyright IBM Corp. All Rights Reserved.
# #
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail
ENV_FILE="${ANTENNA_ENV_FILE:-scripts/00_env.local.sh}"
[[ -f "$ENV_FILE" ]] || ENV_FILE="scripts/00_env.sh"
source "$ENV_FILE"

command -v envsubst >/dev/null 2>&1 || { echo "envsubst missing. Install gettext-base."; exit 1; }

mkdir -p deploying/transmitter/configs/js deploying/receiver/configs/js

for f in docker-compose.yml \
         configs/transmitter/configs/storage.yml \
         configs/transmitter/configs/transmitter.yml \
         configs/transmitter/configs/js/verify_agent_registry_mapper.js \
         configs/receiver/configs/storage.yml \
         configs/receiver/configs/receiver.yml \
         configs/receiver/configs/js/vault_agent_registry_action.js; do
  if [[ "$f" == docker-compose.yml ]]; then
    out="docker-compose.yml"
  else
    out="deploying/${f#configs/}"
  fi
  mkdir -p "$(dirname "$out")"
  envsubst < "$f.template" > "$out"
done

chmod -R 755 deploying
chmod -R 644 deploying/transmitter/configs/keys/* deploying/receiver/configs/keys/* || true
chmod -R 777 db-tx db-rx

echo "Rendered templates into active deploying/ tree."
