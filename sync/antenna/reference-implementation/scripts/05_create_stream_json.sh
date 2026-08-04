#!/usr/bin/env bash

# Copyright IBM Corp. All Rights Reserved.
# #
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail
ENV_FILE="${ANTENNA_ENV_FILE:-scripts/00_env.local.sh}"
[[ -f "$ENV_FILE" ]] || ENV_FILE="scripts/00_env.sh"
source "$ENV_FILE"

cat > create_stream_post_data.json <<EOF
{
  "name": "verify-agent-registry-to-vault-agent-registry",
  "metadataUrl": "${NGROK_URL}/.well-known/ssf-configuration",
  "authorizationScheme": {
    "type": "urn:ietf:rfc:6749",
    "attributes": {
      "grantType": "client_credentials",
      "clientId": "${VERIFY_CLIENT_ID}",
      "clientSecret": "${VERIFY_CLIENT_SECRET}",
      "clientAuthenticationMethod": "client_secret_post",
      "discoveryURI": "https://${VERIFY_TENANT_HOST}/oauth2/.well-known/openid-configuration"
    }
  },
  "ssfStream": {
    "delivery": {
      "method": "urn:ietf:rfc:8936"
    },
    "events_requested": [
      "${SESSION_EVENT}"
    ]
  }
}
EOF

python3 -m json.tool create_stream_post_data.json
