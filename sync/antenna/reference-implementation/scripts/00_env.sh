#!/usr/bin/env bash
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0

# Run Antenna helpers from reference-implementation/. Credentials come from root lab.env.
ENV_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ROOT_DIR=$(cd "$ENV_DIR/../../../.." && pwd)
: "${UC3_ENV_FILE:=$ROOT_DIR/lab.env}"
[[ -f "$UC3_ENV_FILE" ]] || { echo "Missing $UC3_ENV_FILE; copy lab.env.example to lab.env in the repository root." >&2; return 1 2>/dev/null || exit 1; }
source "$UC3_ENV_FILE"
: "${VERIFY_CLIENT_ID:?}" "${VERIFY_CLIENT_SECRET:?}" "${NGROK_URL:?}"
export LAB_NAME="verify-vault-agent-registry"
export HOST_IP="localhost"
export VERIFY_AGENT_API_PATH="/v1.0/Agents"
export VAULT_ADDR_HOST="$VAULT_ADDR"
export VAULT_ADDR_FROM_ANTENNA="http://host.docker.internal:8200"
export VAULT_TOKEN="$(cat "$ROOT_DIR/.uc3-sync-token")"
export VAULT_POLICY="course-tool-ceiling"
export VAULT_AGENT_ACL_POLICY="course-tool-subject"
export VAULT_MOUNT_ACCESSOR="$(jq -er '.data.mount_accessor // ("oauth-resource-server_root_" + .data.config_id)' "$ROOT_DIR/.runtime/vault-profile.json")"
export VAULT_AGENT_REGISTRY_CEILING_FIELD="ceiling_policies"
export TX_PORT="9044"
export RX_PORT="9043"
export TX_CONTAINER="${LAB_NAME}-transmitter"
export RX_CONTAINER="${LAB_NAME}-receiver"
export SUBJECT_FORMAT="opaque"
export PATCH_EVENT="urn:ietf:params:scim:event:prov:patch:full"
export CREATE_EVENT="urn:ietf:params:scim:event:prov:create:full"
