#!/usr/bin/env bash

# Copyright IBM Corp. All Rights Reserved.
# #
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail
TOKEN="${1:-}"
[[ -n "$TOKEN" ]] || { echo "Usage: $0 <jwt>" >&2; exit 2; }
python3 - "$TOKEN" <<'PY'
import base64,json,sys
parts=sys.argv[1].split('.')
if len(parts)!=3: raise SystemExit('Not a JWT')
p=parts[1]+'='*((4-len(parts[1])%4)%4)
obj=json.loads(base64.urlsafe_b64decode(p.encode()))
keep=['iss','sub','aud','client_id','azp','scope','may_act','act','authorization_details','iat','exp']
print(json.dumps({k:obj[k] for k in keep if k in obj},indent=2))
PY
