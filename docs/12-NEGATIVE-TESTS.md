<!--
Copyright IBM Corp. All Rights Reserved.

SPDX-License-Identifier: Apache-2.0
-->

# 12. Validate denials, suspension and recovery

**Purpose:** distinguish policy enforcement from an expired token or network failure. Run a successful Step 10 credential read immediately before each denial test. Refresh tokens with `bash verify/scripts/03_exchange_obo_token.sh` as needed; repeat human sign-in when its token expires.

## 12.1 Deny a read to another existing path

Create a separate dummy path with the administrator credential, then try to read it with the current credential JWT:

```bash
cd "$UC3_ROOT"
curl --fail-with-body -sS -X POST -H "X-Vault-Token: $VAULT_ADMIN_TOKEN" \
 -H 'Content-Type: application/json' --data '{"data":{"api_key":"unapproved-demo-key"}}' \
 "$VAULT_ADDR/v1/course-tools/data/unapproved-enrollment" -o /dev/null
python3 verify/scripts/06_check_jwt_contract.py credential .runtime/credential.token
export CREDENTIAL_TOKEN="$(cat .runtime/credential.token)"
code=$(curl -sS -o .runtime/wrong-path.json -w '%{http_code}' \
 -H "X-Vault-Token: $CREDENTIAL_TOKEN" "$VAULT_ADDR/v1/course-tools/data/unapproved-enrollment")
printf 'Wrong-path status=%s\n' "$code"
test "$code" = 403
```

**Expected:** 403 while the same current token can read the approved path. The other path exists, so a 404 does not count as the required authorization denial.

## 12.2 Deny a write to the approved path

```bash
code=$(curl -sS -o .runtime/write-denial.json -w '%{http_code}' -X POST \
 -H "X-Vault-Token: $CREDENTIAL_TOKEN" -H 'Content-Type: application/json' \
 --data '{"data":{"api_key":"must-not-be-written"}}' \
 "$VAULT_ADDR/v1/course-tools/data/premium-enrollment")
printf 'Write status=%s\n' "$code"
test "$code" = 403
```

**Expected:** 403. Repeat Step 7A to confirm the stored key is unchanged.

## 12.3 Deny bypassing the task exchange

```bash
code=$(curl -sS -o .runtime/task-bypass.json -w '%{http_code}' -X POST "$VERIFY_TOKEN_URL" \
 -H 'Content-Type: application/x-www-form-urlencoded' \
 --data-urlencode 'grant_type=urn:ietf:params:oauth:grant-type:token-exchange' \
 --data-urlencode "client_id=$CREDENTIAL_CLIENT_ID" --data-urlencode "client_secret=$CREDENTIAL_CLIENT_SECRET" \
 --data-urlencode 'subject_token@.runtime/subject.token' \
 --data-urlencode 'subject_token_type=urn:ietf:params:oauth:token-type:access_token' \
 --data-urlencode 'actor_token@.runtime/actor.token' \
 --data-urlencode 'actor_token_type=urn:ietf:params:oauth:token-type:access_token' \
 --data-urlencode 'requested_token_type=urn:ietf:params:oauth:token-type:access_token' \
 --data-urlencode 'authorization_details@.runtime/credential-rar.json')
printf 'Task-bypass issuance status=%s\n' "$code"
jq -e 'has("access_token")|not' .runtime/task-bypass.json
```

**Expected:** non-2xx issuance and no access token, attributable to the wrong subject application/missing task. An expired human or actor token does not prove Actor Criteria enforcement; refresh valid inputs and repeat if necessary.

## 12.4 Suspend the agent and test a still-current credential

1. Obtain a fresh credential token with Step 10.2 and confirm its approved-path read succeeds.
2. In **Identities → AI agents**, open Course Assistant and choose Suspend. Save the change.
3. In Terminal B inspect delivery:

```bash
cd "$ANTENNA_ROOT"
docker compose logs --tail=150 antenna-transmitter antenna-receiver
cd "$UC3_ROOT"
curl --fail-with-body -sS -H "X-Vault-Token: $VAULT_ADMIN_TOKEN" \
 "$VAULT_ADDR/v1/identity/entity/name/verify-agent-$VERIFY_AGENT_ID" -o .runtime/suspended-entity.json
jq -e '.data.disabled==true' .runtime/suspended-entity.json
export VAULT_AGENT_ENTITY_ID="$(jq -er '.data.id' .runtime/suspended-entity.json)"
code=$(curl -sS -o .runtime/suspended-registration.json -w '%{http_code}' \
 -H "X-Vault-Token: $VAULT_ADMIN_TOKEN" \
 "$VAULT_ADDR/v1/agent-registry/registration/entity-id/$VAULT_AGENT_ENTITY_ID")
printf 'Suspended registration status=%s\n' "$code"
python3 verify/scripts/06_check_jwt_contract.py credential .runtime/credential.token
code=$(curl -sS -o .runtime/suspended-read.json -w '%{http_code}' \
 -H "X-Vault-Token: $(cat .runtime/credential.token)" \
 "$VAULT_ADDR/v1/course-tools/data/premium-enrollment")
printf 'Suspended runtime read status=%s\n' "$code"
test "$code" = 403
```

**Expected:** disabled entity, removed registration (normally 404), still-current credential JWT and denied read. Wait for actual webhook/SSF propagation before judging the result. If the token expires first, the read does not prove lifecycle enforcement; repeat from the positive baseline with a fresh token.

The receiver disables before deleting registration. A previously released static API key is not recalled by suspension; backend key rotation/revocation is needed for that separate control.

## 12.5 Reactivate and validate recovery

Activate Course Assistant in Verify, observe the event, then:

```bash
bash vault/scripts/05_validate_synced_agent.sh
bash verify/scripts/03_exchange_obo_token.sh
```

**Expected:** the entity UUID matches `VAULT_AGENT_ENTITY_ID`, the registration is restored, and a fresh credential read/enrollment succeeds. If the human token expired during the lifecycle test, repeat Step 10.1 first.

## 12.6 Distinguish credential retrieval from API authentication

Store an intentionally wrong dummy API key with the administrator token:

```bash
curl --fail-with-body -sS -X POST -H "X-Vault-Token: $VAULT_ADMIN_TOKEN" \
 -H 'Content-Type: application/json' --data '{"data":{"api_key":"intentionally-wrong-demo-key"}}' \
 "$VAULT_ADDR/v1/course-tools/data/premium-enrollment" -o /dev/null
```

In the portal try PREM-801. **Expected:** Vault read can succeed, while the protected Course API returns 403. Restore the correct key immediately:

```bash
jq -nc --arg key "$PREMIUM_API_EXPECTED_KEY" '{data:{api_key:$key}}' > .runtime/restore-key.json
curl --fail-with-body -sS -X POST -H "X-Vault-Token: $VAULT_ADMIN_TOKEN" \
 -H 'Content-Type: application/json' --data-binary @.runtime/restore-key.json \
 "$VAULT_ADDR/v1/course-tools/data/premium-enrollment" -o /dev/null
rm .runtime/restore-key.json
```

**Expected:** PREM-801 succeeds again.

## 12.7 Repeat with another human

Create/entitle a second distinct user as in Step 6.3. Sign out of the portal and sign in as that user, then enroll in PREM-801. **Expected:** the human task subject changes, while final AgentID, alias and Vault entity remain the same. Do not provision another Vault entity for this user.

Record actual results in `docs/ACCEPTANCE-RESULTS.md`. A checklist entry is not a test result until observed.
