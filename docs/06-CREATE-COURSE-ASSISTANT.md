<!--
Copyright IBM Corp. All Rights Reserved.

SPDX-License-Identifier: Apache-2.0
-->

# 6. Create the Verify clients, human and agent

**Purpose:** create every Verify-side identity used by the lab. The required set is one recipe API client and four runtime OAuth applications: Portal, Runtime, Task Exchange and Credential Exchange. Use dedicated lab applications so the trusted AgentID mappings and policy changes cannot affect other applications.

## 6.1 Create the recipe API client

1. Sign in to the IBM Verify administration console as an administrator.
2. Open **Security → API access** and add an API client named **UC3 Recipe API Client**.
3. Enable the authorization-detail administration entitlement (`manageAuthDetailTypes`) and the API entitlements that allow reading AI agent records in this tenant. The same client is used by Antenna to read the current agent record and authenticate SSF stream requests, following the recipe configuration.
4. Save it and copy its client ID and secret into `VERIFY_CLIENT_ID` and `VERIFY_CLIENT_SECRET` in `lab.env`.

Console labels for agent permissions depend on tenant rollout. Confirm access with the actual GET in Step 6.5; a saved client alone is not proof that access was granted.

```bash
cd "$UC3_ROOT"
source lab.env
curl --fail-with-body -sS -X POST "$VERIFY_TOKEN_URL" \
 -H 'Content-Type: application/x-www-form-urlencoded' \
 --data-urlencode grant_type=client_credentials \
 --data-urlencode "client_id=$VERIFY_CLIENT_ID" \
 --data-urlencode "client_secret=$VERIFY_CLIENT_SECRET" \
 -o .runtime/verify-management-token.json
export VERIFY_MGMT_TOKEN="$(jq -er '.access_token' .runtime/verify-management-token.json)"
jq -e '.access_token|type=="string" and length>0' .runtime/verify-management-token.json
```

**Expected:** `true`. The recipe uses the discovered OAuth token endpoint with this API client for both agent API access and SSF stream authentication. The checkpoint verifies that this credential works on your tenant before Antenna is started.

## 6.2 Create the OAuth applications

Open **Applications → Applications → Add application → OpenID Connect**. Complete mandatory display/owner fields and create each of the following. Select confidential clients with `client_secret_post` (credentials in the form body) for this lab; use JWT access tokens signed with RS256. Save each application before recording credentials.

| Name | Grant | Additional settings | lab.env fields |
|---|---|---|---|
| Course Portal | Authorization Code | Response type `code`; query response; PKCE S256 required; redirect exactly `http://localhost:4000/callback`; scopes `openid profile email` | `WEB_CLIENT_ID`, `WEB_CLIENT_SECRET` |
| Course Assistant Runtime | Client Credentials | JWT access token | `ACTOR_CLIENT_ID`, `ACTOR_CLIENT_SECRET` |
| Course Task Exchange | Token Exchange | Settings below | `TASK_CLIENT_ID`, `TASK_CLIENT_SECRET` |
| Course Credential Exchange | Token Exchange | Settings below | `CREDENTIAL_CLIENT_ID`, `CREDENTIAL_CLIENT_SECRET` |

For **both exchange applications**, open **Sign-on → Token exchange** and configure:

- Subject token type: Access Token.
- Actor token type: Access Token; require the actor token.
- Requested/output token type: Access Token.
- Keep **Skip default actor validation** disabled.
- Restrict authorization detail types; reject unknown types. Attach the types in Step 8.
- Set nominal access-token lifetime to 300 seconds where supported; the later JWT check shows the actual issued expiry.

Do not map a constant subject on the Portal or Task Exchange. The Runtime and Credential Exchange subject mappings are configured in Step 8. This lab does not require an explicit request `audience`; if your organization enforces one, configure matching issuance/profile restrictions and verify the actual issued `aud` before adding it.

**Expected:** four distinct saved OAuth clients and two distinct exchange client credentials. All `*_CLIENT_*` fields in `lab.env` have actual values.

## 6.3 Create and entitle the human test account

In **Users & groups → Users** (or the tenant's user directory), add a dedicated user, **Course Learner**, using an email address you control. Complete account activation/password setup. Open **Course Portal → Entitlements**, grant this user access and save. If the tenant uses an external identity provider, provision/entitle an equivalent test user through that provider.

**Expected:** the user is active, can sign in and is entitled to Course Portal. A second distinct user can be added later to validate identity reuse across humans.

## 6.4 Onboard and activate Course Assistant

1. Open **Identities → AI agents**.
2. Add/onboard **Course Assistant**, description **Assists a human with premium course enrollment**.
3. Assign the responsible human owner and save the record.
4. Open its identity/authentication or OAuth-client associations settings. Associate **Course Assistant Runtime** with purpose **`agent_id`**.
5. Complete any approval workflow, then activate it. Do not assume a requested status bypasses approval.
6. Record its generated registry UUID in `VERIFY_AGENT_ID` in `lab.env`.

This is the registry UUID, not the actor client ID. Use the supported association UI; the lab does not POST the read-only `oauthClients` attribute to fabricate an association.

**Expected:** the saved agent shows ACTIVE and exactly one runtime association with purpose `agent_id`.

## 6.5 Confirm the authoritative API view

```bash
source lab.env
curl --fail-with-body -sS \
 -H "Authorization: Bearer $VERIFY_MGMT_TOKEN" \
 -H 'Accept: application/scim+json' \
 -H "x-forwarded-host: $VERIFY_TENANT_HOST" \
 "https://$VERIFY_TENANT_HOST/v1.0/Agents/$VERIFY_AGENT_ID" \
 -o .runtime/verify-agent.json
jq -e --arg id "$VERIFY_AGENT_ID" --arg client "$ACTOR_CLIENT_ID" '
 .id==$id and .status=="ACTIVE" and
 ([.oauthClients[] | select(.clientId==$client and (.purposes|index("agent_id")!=null))]|length==1)
' .runtime/verify-agent.json
```

**Expected:** `true`. A 401/403 requires fixing the management client's access. A 404 requires checking the actual registry UUID and Agent API availability/path. If the response lacks the explicit purpose, return to the association settings; do not continue with a synthetic association.

**Stop checkpoint:** setup API token and Agent GET succeed, human is entitled, all OAuth clients exist, agent is ACTIVE and its association is visible through the API. Continue to Step 7.
