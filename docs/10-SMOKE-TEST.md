<!--
Copyright IBM Corp. All Rights Reserved.

SPDX-License-Identifier: Apache-2.0
-->

# 10. Validate token issuance and the first JWT credential read

**Purpose:** prove each remote authorization boundary separately before the browser demonstration. Keep the portal stopped while the sign-in helper owns port 4000.

## 10.1 Authenticate the human with PKCE

```bash
cd "$UC3_ROOT"
source lab.env
python3 verify/scripts/07_login_subject.py
python3 verify/scripts/06_check_jwt_contract.py subject .runtime/subject.token
```

Sign in in the opened browser as Course Learner and complete any required consent. The helper validates OAuth state, exchanges the code with the matching PKCE verifier, writes the token privately and releases port 4000.

**Expected:** the browser returns to `http://localhost:4000/callback`; the terminal reports a saved token and `PASS: subject claim contract`. The subject must identify the human. A redirect error requires checking exact hostname, scheme, port and path. If the helper times out, run it again and use the new authorization URL.

## 10.2 Authenticate the agent and perform both exchanges

```bash
bash verify/scripts/03_exchange_obo_token.sh
```

The helper obtains a fresh actor token, validates its identity, sends the task exchange, checks its output, and sends the credential exchange. It stops on a failed HTTP call or failed claim check, and clears previous output token files before issuance so stale files cannot masquerade as success.

| Output | Required observed claims |
|---|---|
| Actor | `sub=VERIFY_AGENT_ID`, `client_id=ACTOR_CLIENT_ID` |
| Task | Human `sub`, immediate `act.sub=VERIFY_AGENT_ID`, granted PREM-801 task RAR |
| Credential | `sub=VERIFY_AGENT_ID`, immediate `act.sub=VERIFY_AGENT_ID`, exact Vault read RAR |

**Expected:** all three `PASS` checks and a positive remaining lifetime. The helper prints selected claims, never the encoded tokens. Local claim inspection does not verify signatures: Verify validates incoming tokens at issuance and Vault validates the presented credential JWT.

If the human token has expired, repeat Step 10.1, then rerun the exchange helper. Do not create a human Vault alias when a credential token has the wrong subject; fix its mapping instead.

## 10.3 Read the secret directly with the Verify JWT

```bash
python3 verify/scripts/06_check_jwt_contract.py credential .runtime/credential.token
export CREDENTIAL_TOKEN="$(cat .runtime/credential.token)"
code=$(curl -sS -o .runtime/runtime-read.json -w '%{http_code}' \
 -H "X-Vault-Token: $CREDENTIAL_TOKEN" \
 "$VAULT_ADDR/v1/course-tools/data/premium-enrollment")
printf 'Vault runtime HTTP status=%s\n' "$code"
test "$code" = 200
jq -e --arg key "$PREMIUM_API_EXPECTED_KEY" '.data.data.api_key==$key' .runtime/runtime-read.json
rm .runtime/runtime-read.json
```

**Expected:** HTTP 200 and `true`. No Vault login is performed. The Verify JWT is presented directly in `X-Vault-Token`; it is not the Vault root or synchronization token. The namespace is still root.

A 403 requires checking the current JWT, exact issuer, permanent alias binding, entity enabled state, subject ACL, registration ceiling and RAR. Equal-subject/actor processing must succeed on the actual licensed build; retain the real validation error if it does not. Do not suppress `act` to hide a failed check.

**Stop checkpoint:** human login, actor token, task exchange, credential exchange and JWT credential read all pass. Continue to Step 11.
