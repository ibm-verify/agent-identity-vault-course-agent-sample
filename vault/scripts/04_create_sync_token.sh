#!/usr/bin/env bash

# Copyright IBM Corp. All Rights Reserved.
# #
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail
DIR=$(cd "$(dirname "$0")" && pwd); ROOT=$(cd "$DIR/.." && pwd)
source "$DIR/_common.sh"; need_admin_token
vault policy write verify-agent-sync "$ROOT/policies/verify-agent-sync.hcl"
echo 'Creating a short-lived reference sync token (8h) for the demo.'
vault token create -policy=verify-agent-sync -ttl=8h -format=json | tee /tmp/course-demo-sync-token.json | jq '{auth:{client_token:"<redacted>",policies:.auth.policies,lease_duration:.auth.lease_duration}}'
echo
echo 'Copy the actual token securely from /tmp/course-demo-sync-token.json -> .auth.client_token'
echo 'Export it as VAULT_SYNC_TOKEN for Antenna/custom synchronization. Delete the temp file after use.'
