#!/usr/bin/env bash

# Copyright IBM Corp. All Rights Reserved.
# #
# SPDX-License-Identifier: Apache-2.0

# IBM Verify Agent Registry -> HashiCorp Vault Agent Registry sync lab.
# Template defaults. Copy to scripts/00_env.local.sh, edit the local copy, and keep secrets out of Git.

export LAB_NAME="verify-vault-agent-registry"

# On Mac, localhost works for host-side curl calls to the containers.
export HOST_IP="localhost"

# Fill this after you start ngrok. Example: https://abc-123.ngrok-free.app
export NGROK_URL="CHANGEME_NGROK_HTTPS_URL"

# IBM Verify tenant and service client that can read Agent Registry data.
# Host only, no https:// prefix.
export VERIFY_TENANT_HOST="CHANGEME.verify.ibmcloudsecurity.com"
export VERIFY_CLIENT_ID="CHANGEME_VERIFY_CLIENT_ID"
export VERIFY_CLIENT_SECRET="CHANGEME_VERIFY_CLIENT_SECRET"
export VERIFY_AGENT_API_PATH="/v1.0/Agents"
# Exact iss claim used by Vault OAuth aliases. Include /oauth2 and no trailing slash.
export VERIFY_ISSUER="https://CHANGEME.verify.ibmcloudsecurity.com/oauth2"

# Vault access.
# VAULT_ADDR_HOST is used by scripts running on your Mac.
# VAULT_ADDR_FROM_ANTENNA is used inside Antenna receiver container.
export VAULT_ADDR_HOST="http://127.0.0.1:8200"
export VAULT_ADDR_FROM_ANTENNA="http://host.docker.internal:8200"
export VAULT_ADDR="$VAULT_ADDR_FROM_ANTENNA"
# IMPORTANT: Use the restricted provisioning token created by vault/scripts/04_create_sync_token.sh
export VAULT_TOKEN="CHANGEME_RESTRICTED_VAULT_SYNC_TOKEN"
export VAULT_NAMESPACE=""

# Agent Registry ceiling policy for the Course Assistant.
export VAULT_POLICY="course-tool-ceiling"

# Auth mount accessor used for entity aliases.
# Use the OAuth Resource Server profile mount accessor produced by vault/scripts/02_get_oauth_profile_binding.sh.
export VAULT_MOUNT_ACCESSOR="CHANGEME_AUTH_MOUNT_ACCESSOR"

# Vault Agent Registry field that carries the authorization ceiling.
export VAULT_AGENT_REGISTRY_CEILING_FIELD="ceiling_policies"

export TX_PORT="9044"
export RX_PORT="9043"
export SESSION_EVENT="https://schemas.openid.net/secevent/caep/event-type/session-revoked"

export TX_CONTAINER="${LAB_NAME}-transmitter"
export RX_CONTAINER="${LAB_NAME}-receiver"
