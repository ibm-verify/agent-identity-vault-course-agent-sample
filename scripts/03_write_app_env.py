#!/usr/bin/env python3
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0

"""Build the portal configuration from the exported lab settings; exclude provisioning secrets."""
import json, os
from pathlib import Path
root=Path(__file__).resolve().parents[1]
required=['VERIFY_ISSUER','VERIFY_TOKEN_URL','VERIFY_AGENT_ID','WEB_CLIENT_ID','WEB_CLIENT_SECRET','ACTOR_CLIENT_ID','ACTOR_CLIENT_SECRET','TASK_CLIENT_ID','TASK_CLIENT_SECRET','CREDENTIAL_CLIENT_ID','CREDENTIAL_CLIENT_SECRET','SESSION_SECRET','PREMIUM_API_EXPECTED_KEY']
values={k:os.environ.get(k,'') for k in required}
for key,value in values.items():
 if not value or 'REPLACE_' in value: raise SystemExit('Fill '+key+' in lab.env first')
values.update(PORT='4000',BASE_URL='http://localhost:4000',REDIRECT_URI='http://localhost:4000/callback',WEB_SCOPE='openid profile email',VAULT_ADDR=os.environ.get('VAULT_ADDR','http://127.0.0.1:8200'),VAULT_NAMESPACE=os.environ.get('VAULT_NAMESPACE',''),VAULT_SECRET_API_PATH='course-tools/data/premium-enrollment',VAULT_SECRET_FIELD='api_key',PREMIUM_API_URL='http://127.0.0.1:4000/api/premium/enroll',SHOW_SAFE_TOKEN_CLAIMS='true')
p=root/'app/.env';p.write_text(''.join(k+'='+json.dumps(v)+'\n' for k,v in values.items()));p.chmod(0o600)
print('PASS: app/.env written; no Vault provisioning or Verify setup secret included')
