#!/usr/bin/env bash
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail
umask 077
: "${VERIFY_TOKEN_URL:?}" "${TASK_CLIENT_ID:?}" "${TASK_CLIENT_SECRET:?}" "${CREDENTIAL_CLIENT_ID:?}" "${CREDENTIAL_CLIENT_SECRET:?}" "${ACTOR_CLIENT_ID:?}" "${ACTOR_CLIENT_SECRET:?}" "${VERIFY_AGENT_ID:?}"
DIR=$(cd "$(dirname "$0")" && pwd)
mkdir -p .runtime
# Remove previous outputs so a failure cannot be mistaken for a fresh successful issuance.
rm -f .runtime/actor.token .runtime/task.token .runtime/credential.token
python3 "$DIR/06_check_jwt_contract.py" subject .runtime/subject.token
curl --fail-with-body -sS -X POST "$VERIFY_TOKEN_URL" -H 'Content-Type: application/x-www-form-urlencoded' \
 --data-urlencode grant_type=client_credentials --data-urlencode "client_id=$ACTOR_CLIENT_ID" \
 --data-urlencode "client_secret=$ACTOR_CLIENT_SECRET" -o .runtime/actor-response.json
jq -erj '.access_token' .runtime/actor-response.json > .runtime/actor.token
python3 "$DIR/06_check_jwt_contract.py" actor .runtime/actor.token
ACTOR_TOKEN=$(cat .runtime/actor.token)
request() {
 curl --fail-with-body -sS -X POST "$VERIFY_TOKEN_URL" -H 'Content-Type: application/x-www-form-urlencoded' \
 --data-urlencode 'grant_type=urn:ietf:params:oauth:grant-type:token-exchange' \
 --data-urlencode "client_id=$1" --data-urlencode "client_secret=$2" \
 --data-urlencode "subject_token@$3" \
 --data-urlencode 'subject_token_type=urn:ietf:params:oauth:token-type:access_token' \
 --data-urlencode "actor_token=$ACTOR_TOKEN" \
 --data-urlencode 'actor_token_type=urn:ietf:params:oauth:token-type:access_token' \
 --data-urlencode 'requested_token_type=urn:ietf:params:oauth:token-type:access_token' \
 --data-urlencode "authorization_details@$4"
}
jq -nc --arg ref "$(python3 -c 'import uuid; print(uuid.uuid4())')" '[{type:"urn:ibm:demo:verify:course_credential_task",action:"premium_enroll",courseId:"PREM-801",reference:$ref}]' > .runtime/task-rar.json
request "$TASK_CLIENT_ID" "$TASK_CLIENT_SECRET" .runtime/subject.token .runtime/task-rar.json > .runtime/task-response.json
jq -erj '.access_token' .runtime/task-response.json > .runtime/task.token
python3 "$DIR/06_check_jwt_contract.py" task .runtime/task.token
jq -nc '[{type:"vault:path_access",path:"course-tools/data/premium-enrollment",capabilities:["read"]}]' > .runtime/credential-rar.json
request "$CREDENTIAL_CLIENT_ID" "$CREDENTIAL_CLIENT_SECRET" .runtime/task.token .runtime/credential-rar.json > .runtime/credential-response.json
jq -erj '.access_token' .runtime/credential-response.json > .runtime/credential.token
python3 "$DIR/06_check_jwt_contract.py" credential .runtime/credential.token
printf 'PASS: fresh actor, task and credential tokens saved privately in .runtime/\n'
