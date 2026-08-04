#!/usr/bin/env bash

# Copyright IBM Corp. All Rights Reserved.
# #
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail
ENV_FILE="${ANTENNA_ENV_FILE:-scripts/00_env.local.sh}"
[[ -f "$ENV_FILE" ]] || ENV_FILE="scripts/00_env.sh"
source "$ENV_FILE"

H="X-Vault-Token: ${VAULT_TOKEN}"
NS=()
if [[ -n "${VAULT_NAMESPACE}" ]]; then
  NS=(-H "X-Vault-Namespace: ${VAULT_NAMESPACE}")
fi

tmp=$(mktemp)
curl -sS -H "$H" "${NS[@]}" "${VAULT_ADDR_HOST}/v1/sys/auth" > "$tmp"
python3 - "$tmp" <<'PY'
import sys,json
with open(sys.argv[1]) as f:
    data=json.load(f).get('data',{})
for path, v in data.items():
    print(f"{path:30s} type={v.get('type',''):12s} accessor={v.get('accessor','')}")
PY
rm -f "$tmp"
