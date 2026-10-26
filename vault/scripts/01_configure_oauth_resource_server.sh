#!/usr/bin/env bash

# Copyright IBM Corp. All Rights Reserved.
# #
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail
DIR=$(cd "$(dirname "$0")" && pwd); ROOT=$(cd "$DIR/.." && pwd)
source "$DIR/_common.sh"; need_admin_token
: "${VERIFY_ISSUER:?export VERIFY_ISSUER, e.g. https://tenant/oauth2}"
: "${VERIFY_JWKS_URI:?Obtain jwks_uri from the discovery document in Step 5}"
: "${VAULT_AUDIENCE:=vault-course-tools}"
: "${VAULT_OAUTH_PROFILE:=course-verify}"
TMP=$(mktemp)
sed -e "s#__VERIFY_ISSUER__#${VERIFY_ISSUER}#g" \
    -e "s#__VERIFY_JWKS_URI__#${VERIFY_JWKS_URI}#g" \
    -e "s#__VAULT_AUDIENCE__#${VAULT_AUDIENCE}#g" \
    "$ROOT/config/course-verify-oauth-profile.json.template" > "$TMP"
vault write "sys/config/oauth-resource-server/$VAULT_OAUTH_PROFILE" @"$TMP"
rm -f "$TMP"
vault read "sys/config/oauth-resource-server/$VAULT_OAUTH_PROFILE"
