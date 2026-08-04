#!/usr/bin/env bash

# Copyright IBM Corp. All Rights Reserved.
# #
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail
DIR=$(cd "$(dirname "$0")" && pwd); ROOT=$(cd "$DIR/.." && pwd)
source "$DIR/_common.sh"; need_admin_token
: "${VAULT_OAUTH_PROFILE:=course-verify}"
JSON=$(vault read -format=json "sys/config/oauth-resource-server/$VAULT_OAUTH_PROFILE")
CONFIG_ID=$(printf '%s' "$JSON" | jq -r '.data.config_id')
[[ -n "$CONFIG_ID" && "$CONFIG_ID" != null ]] || { echo 'Could not read config_id'; exit 1; }
# Tested root-namespace binding pattern from the supplied IBM Verify/Vault reference implementation.
NAMESPACE_ID="${VAULT_NAMESPACE_ID:-root}"
ACCESSOR="oauth-resource-server_${NAMESPACE_ID}_${CONFIG_ID}"
cat > "$ROOT/.oauth-runtime.env" <<EOT
export VAULT_OAUTH_PROFILE="$VAULT_OAUTH_PROFILE"
export VAULT_OAUTH_CONFIG_ID="$CONFIG_ID"
export VAULT_OAUTH_MOUNT_ACCESSOR="$ACCESSOR"
EOT
printf 'VAULT_OAUTH_CONFIG_ID=%s\nVAULT_OAUTH_MOUNT_ACCESSOR=%s\nSaved: %s\n' "$CONFIG_ID" "$ACCESSOR" "$ROOT/.oauth-runtime.env"
