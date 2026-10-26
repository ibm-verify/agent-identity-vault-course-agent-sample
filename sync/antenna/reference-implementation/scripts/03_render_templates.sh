#!/usr/bin/env bash
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail
source scripts/00_env.sh

command -v envsubst >/dev/null 2>&1 || { echo "envsubst missing. On macOS, install gettext and add its bin directory to PATH."; exit 1; }

mkdir -p deploying/transmitter/configs/js deploying/receiver/configs/js

for f in docker-compose.yml \
         configs/transmitter/configs/storage.yml \
         configs/transmitter/configs/custom_events.yml \
         configs/transmitter/configs/transmitter.yml \
         configs/transmitter/configs/js/verify_agent_registry_mapper.js \
         configs/receiver/configs/storage.yml \
         configs/receiver/configs/custom_events.yml \
         configs/receiver/configs/receiver.yml \
         configs/receiver/configs/js/vault_agent_registry_action.js; do
  if [[ "$f" == docker-compose.yml ]]; then
    out="docker-compose.yml"
  else
    out="deploying/${f#configs/}"
  fi
  mkdir -p "$(dirname "$out")"
  if [[ "$f" == *.js ]]; then
    python3 scripts/render_js.py "$f.template" "$out"
  else
    envsubst < "$f.template" > "$out"
  fi
done

# Lab permissions allow the container user to read mounted configuration.
# These files include credentials; use stricter ownership/permissions in production.
# Lab permissions allow the container user to read mounted configuration.
# These files include credentials; use stricter ownership/permissions in production.
chmod -R 755 deploying
chmod -R 644 deploying/transmitter/configs/keys/* deploying/receiver/configs/keys/* || true
chmod -R 777 db-tx db-rx

echo "Rendered templates into active deploying/ tree."
