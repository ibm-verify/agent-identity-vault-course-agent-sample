#!/usr/bin/env bash

# Copyright IBM Corp. All Rights Reserved.
# #
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail
ENV_FILE="${ANTENNA_ENV_FILE:-scripts/00_env.local.sh}"
[[ -f "$ENV_FILE" ]] || ENV_FILE="scripts/00_env.sh"
source "$ENV_FILE"

docker logs -f "${TX_CONTAINER}" "${RX_CONTAINER}" 2>&1 | grep -iE \
"verify_agent_registry_mapper|vault_agent_registry_action|Generated Agent Registry|status=|operation=|agentIdClients|runtime aliases|UPSERT|DELETE|Vault|Agent Registry|Alias|entity|COMPLETE|SKIPPED|failed|error|No IBM Verify Agent|oauthClients|purpose=agent_id"
