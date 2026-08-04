#!/usr/bin/env bash

# Copyright IBM Corp. All Rights Reserved.
# #
# SPDX-License-Identifier: Apache-2.0

# Copy to 00_env.sh, edit, then: source verify/scripts/00_env.sh
export VERIFY_TENANT_HOST="YOUR_TENANT.verify.ibm.com"
export VERIFY_ISSUER="https://${VERIFY_TENANT_HOST}/oauth2"
export VERIFY_TOKEN_URL="${VERIFY_ISSUER}/token"

export ACTOR_CLIENT_ID="CHANGEME"
export ACTOR_CLIENT_SECRET="CHANGEME"

export TOKEN_EXCHANGE_CLIENT_ID="CHANGEME"
export TOKEN_EXCHANGE_CLIENT_SECRET="CHANGEME"
# The OIDC Token Exchange application should be configured with this static audience.
export VAULT_AUDIENCE="vault-course-tools"

export VAULT_SECRET_API_PATH="course-tools/data/premium-enrollment"

# Optional IBM Verify management API client for ADT creation.
export VERIFY_MGMT_CLIENT_ID="CHANGEME"
export VERIFY_MGMT_CLIENT_SECRET="CHANGEME"
