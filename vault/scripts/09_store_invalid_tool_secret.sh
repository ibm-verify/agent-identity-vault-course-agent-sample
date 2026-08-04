#!/usr/bin/env bash

# Copyright IBM Corp. All Rights Reserved.
# #
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail
DIR=$(cd "$(dirname "$0")" && pwd); source "$DIR/_common.sh"; need_admin_token
vault kv put course-tools/premium-enrollment api_key='intentionally-wrong-premium-key'
echo 'Stored intentionally wrong demo API key. Premium tool should now return HTTP 403 after Vault read succeeds.'
