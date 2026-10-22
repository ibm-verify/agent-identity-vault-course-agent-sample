#!/usr/bin/env bash
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail
: "${VAULT_ADDR:?}"
python3 verify/scripts/06_check_jwt_contract.py credential .runtime/credential.token
curl --fail-with-body -sS -H "X-Vault-Token: $(cat .runtime/credential.token)" "$VAULT_ADDR/v1/course-tools/data/premium-enrollment" | jq '{data:{data:(.data.data|with_entries(.value="<redacted>")),metadata:.data.metadata}}'
