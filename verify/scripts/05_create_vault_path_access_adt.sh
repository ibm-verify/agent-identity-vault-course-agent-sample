#!/usr/bin/env bash
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail
umask 077
: "${VERIFY_TENANT_HOST:?}" "${VERIFY_MGMT_TOKEN:?}"
DIR=$(cd "$(dirname "$0")/.." && pwd)
mkdir -p .runtime
existing=0
for pair in 'vault-path-access vault:path_access' 'course-task urn:ibm:demo:verify:course_credential_task'; do
 read -r name type <<< "$pair"
 jq -n --arg type "$type" --rawfile schema "$DIR/adt/$name.schema.json" '{type:$type,description:"UC3 course enrollment authorization",schema:$schema,inlineMode:true,consentInlineText:("<div>Allow the Course Assistant demonstration action.</div>"|@base64)}' > ".runtime/$name.create.json"
 code=$(curl -sS -o ".runtime/$name.response.json" -w '%{http_code}' -X POST "https://$VERIFY_TENANT_HOST/v1.0/auth-detail-types" -H "Authorization: Bearer $VERIFY_MGMT_TOKEN" -H 'Content-Type: application/json' --data-binary @".runtime/$name.create.json")
 if [[ $code == 2* ]]; then echo "PASS: created $type";
 elif [[ $code == 409 ]]; then echo "CHECK: $type exists. Inspect its schema in the console before proceeding to the binding step."; existing=1;
 else echo "FAIL: $type HTTP $code; inspect .runtime/$name.response.json"; exit 1; fi
done

if [[ $existing == 1 ]]; then echo "STOP CHECKPOINT: verify compatibility of the existing types before continuing with Step 8.1 bindings."; exit 1; fi
