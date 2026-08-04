#!/usr/bin/env bash

# Copyright IBM Corp. All Rights Reserved.
# #
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail
DIR=$(cd "$(dirname "$0")" && pwd); source "$DIR/_common.sh"; need_admin_token
vault kv put course-tools/premium-enrollment api_key='course-premium-demo-key-2026'
echo 'Stored matching demo API key in Vault.'
