<!--
Copyright IBM Corp. All Rights Reserved.

SPDX-License-Identifier: Apache-2.0
-->

# UC3 setup guide: controlled credential access for course enrollment

Follow this guide from the beginning to configure IBM Agent Identity in IBM Verify, Antenna synchronization and HashiCorp Vault credential access. Every stage includes commands, expected results and a stop checkpoint. Resolve a failed checkpoint before continuing.

Required Verify clients: **one recipe API client**, reused for API setup, Agent GET and SSF authentication, plus **four runtime OAuth applications** (Course Portal, Course Assistant Runtime, Course Task Exchange and Course Credential Exchange). The two exchanges have different subject mappings and remain separate. No additional SSF client is required.

All local inputs are entered in **lab.env**, created from **lab.env.example in the repository root**. Antenna reads that same file automatically. Product accounts and a licensed Vault build are external inputs; the guide creates all lab resources.

For a restart, follow START-HERE.md before beginning. The first-run lab uses the root Vault namespace, a disposable Enterprise dev server and a dummy course API key.

# 3. Prepare the workstation and workspace

**Purpose:** install the tools, unpack the sample and create the local settings file. No Verify applications, Vault policies, identities, secrets or Antenna streams are assumed to exist.

## 3.1 Obtain the required products and accounts

| Requirement | How to prepare | Check before proceeding |
|---|---|---|
| IBM Verify tenant with IBM Agent Identity enabled | Obtain a tenant and administrator access from your IBM service administrator; sign in to its administration console | AI agents, application management and API access administration are available |
| Human test account | Create it in Step 6 | You can complete interactive authentication |
| Licensed Vault Enterprise build | Obtain the binary for your OS/CPU and an evaluation or purchased license with OAuth Resource Server and Agent Registry capabilities through your IBM/HashiCorp representative | Step 4 starts it and Step 5 activates the required feature |
| Antenna container images | Obtain pull access to `icr.io/ibm-verify/ibm-verify-antenna-transmitter:26.03.0` and `icr.io/ibm-verify/ibm-verify-antenna-receiver:26.03.0` | Step 7 can pull both images |
| ngrok account | Create an account at https://ngrok.com and obtain its authentication token | A public HTTPS tunnel can be started |

Product entitlement, a license file and tenant credentials are external inputs. The sample does not create a tenant or issue a product license. These checks must pass before the remaining setup can succeed.

## 3.2 Install workstation tools

The protocol and application flow are independent of OS. The commands below use Bash. On Windows run them in WSL2 with Docker integration. On Linux use your distribution packages and the vendors' installers. Install Node.js with npm, Python 3, curl, jq, OpenSSL, gettext (`envsubst`), Docker Engine/Desktop with Compose, ngrok and the licensed Vault binary.

On macOS, install Homebrew from https://brew.sh if it is not installed, and follow the installer’s displayed PATH instructions. Then:

```bash
brew install node python jq openssl@3 gettext ngrok
export PATH="$(brew --prefix openssl@3)/bin:$(brew --prefix gettext)/bin:$PATH"
```

Install Docker Desktop from https://www.docker.com/products/docker-desktop/, open it and wait for the engine to become ready. Docker Desktop supplies Compose. A configured Colima engine can also be used; select one engine for the entire lab.

Download the licensed Vault binary matching your CPU, extract it to a private directory such as `~/uc3-tools/vault`, make it executable and add that directory to PATH. Put your license in a separate private file. Record its absolute path; do not copy it into the sample repository.

```bash
bash --version
node --version
npm --version
python3 --version
curl --version
jq --version
openssl version
envsubst --version
docker info
docker compose version
ngrok version
vault version
```

**Expected:** every command runs; `docker info` shows a reachable server. Use Node.js 22 or a later supported LTS release. `vault version` must identify your Enterprise binary. A command-not-found error or unavailable Docker server must be resolved now.

## 3.3 Extract and enter the sample

Download the ZIP and extract it with your file manager. Open Terminal B and enter the extracted folder containing `README.md`, `app/`, `verify/`, `vault/` and `sync/`. For a ZIP downloaded to Downloads:

```bash
cd agent-identity-vault-course-agent-sample-main
export UC3_ROOT="$PWD"
umask 077
mkdir -p .runtime
chmod 700 .runtime
cp lab.env.example lab.env
chmod 600 lab.env
```

If the downloaded filename differs, substitute that filename in `unzip`. Keep Terminal B open throughout the setup. `UC3_ROOT` always means this extracted repository root.

**Expected:** `test -f "$UC3_ROOT/app/package.json" && echo PASS` prints `PASS`.

## 3.4 Fill the initial local settings

Open `lab.env` in a text editor. Replace `REPLACE_TENANT_HOST` with the tenant hostname only, without `https://` or a trailing slash. Leave application/agent placeholders until Step 6. Generate a session secret:

```bash
python3 -c 'import secrets; print(secrets.token_urlsafe(48))'
```

Copy that output into `SESSION_SECRET`. The API-key value in this sample is a dummy demonstration credential. Keep `PREMIUM_API_EXPECTED_KEY` unchanged for the first run so all steps use the same value. Set the licensed Vault path separately in Terminal A in Step 4. Do not source `app/.env`; it is an application configuration file, not a shell script.

```bash
source "$UC3_ROOT/lab.env"
printf 'Tenant=%s\nVault=%s\nSecret path=%s\n' "$VERIFY_TENANT_HOST" "$VAULT_ADDR" "$VAULT_SECRET_API_PATH"
```

**Expected:** actual tenant hostname, `http://127.0.0.1:8200` and `course-tools/data/premium-enrollment`. No client secret is displayed.

## Terminal plan

| Terminal | Purpose | Keep running |
|---|---|---|
| A | Vault dev server | Throughout all tests |
| B | Setup, curl, Docker and validation | Throughout setup |
| C | ngrok HTTPS tunnel | Throughout synchronization tests |
| D | Course Portal | During the browser demonstration |

All setup commands run in Terminal B unless another terminal is specified. Proceed to **Step 4** only after the workstation checks pass.


# 4. Start and check Vault Enterprise

**Purpose:** start a disposable licensed server that both the host and Antenna receiver can reach. This guide uses the **root namespace**; `VAULT_NAMESPACE` is empty and no `X-Vault-Namespace` header is sent. Root namespace and root-token authentication are different concepts.

## 4.1 Start the server — Terminal A

Open a new terminal and set the actual absolute license path:

```bash
export VAULT_LICENSE_PATH='/absolute/path/to/vault.hclic'
vault server -dev -dev-root-token-id=root -dev-listen-address=0.0.0.0:8200
```

**Expected:** Vault starts, is initialized and unsealed, and listens on port 8200. Leave this terminal running. If license validation or feature entitlement fails, correct the license/build before continuing.

The listener binds all host interfaces so Docker can reach it. Run this disposable configuration only on an isolated workstation with access to port 8200 restricted. Dev mode keeps its state in memory. Stopping this server discards its configuration and secrets; the guide does not configure raft storage.

## 4.2 Check from Terminal B

```bash
cd "$UC3_ROOT"
source lab.env
curl --fail-with-body -sS "$VAULT_ADDR/v1/sys/health" -o .runtime/vault-health.json
jq -e '.initialized == true and .sealed == false' .runtime/vault-health.json
jq '{version,initialized,sealed}' .runtime/vault-health.json
```

**Expected:** `true`, with your actual Enterprise version. HTTP connection failure means the server/listener is not ready. Do not continue until this check passes.

## 4.3 Check administrator access

```bash
curl --fail-with-body -sS -H "X-Vault-Token: $VAULT_ADMIN_TOKEN" \
 "$VAULT_ADDR/v1/auth/token/lookup-self" -o .runtime/vault-admin-check.json
jq -e '.data.policies | index("root") != null' .runtime/vault-admin-check.json
```

**Expected:** `true` for this new dedicated dev server. The admin credential is used only for setup and inspection. Synchronization will receive a separate restricted token; runtime reads will use a Verify-issued JWT.

**Stop checkpoint:** health and admin checks pass. Proceed to Step 5.


# 5. Configure Vault trust, ACL and registration ceiling

**Purpose:** establish JWT validation, create the demo credential and both permission policies, and issue a restricted provisioning token. Skipping any of these leaves synchronization or runtime authorization incomplete.

| Configuration | Why it is needed |
|---|---|
| Verify OAuth discovery/JWKS | Identify the issuer and signing keys Vault will trust |
| OAuth Resource Server profile | Validate the runtime JWT and require RAR |
| `course-tool-subject` ACL | Grant the agent-subject access to the exact credential path |
| `course-tool-ceiling` | Bound the registered actor's maximum authority |
| `verify-agent-sync`/`uc3-sync` provisioning policy | Allow the receiver to manage identities and registration without secret-read access |
| KV v2 credential | Give the authorized read a real dummy value to retrieve |

## 5.1 Discover the issuer metadata

```bash
cd "$UC3_ROOT"
source lab.env
curl --fail-with-body -sS "$VERIFY_ISSUER/.well-known/openid-configuration" \
 -o .runtime/verify-discovery.json
jq -e --arg issuer "$VERIFY_ISSUER" '.issuer == $issuer and (.jwks_uri|type=="string")' \
 .runtime/verify-discovery.json
export VERIFY_JWKS_URI="$(jq -er '.jwks_uri' .runtime/verify-discovery.json)"
export VERIFY_TOKEN_URL="$(jq -er '.token_endpoint' .runtime/verify-discovery.json)"
printf 'Issuer=%s\nJWKS=%s\n' "$VERIFY_ISSUER" "$VERIFY_JWKS_URI"
curl --fail-with-body -sS "$VERIFY_JWKS_URI" -o .runtime/verify-jwks.json
jq -e '.keys|length>0' .runtime/verify-jwks.json
```

**Expected:** both checks print `true`. If discovery reports another issuer, correct `VERIFY_ISSUER` in `lab.env` and repeat; do not replace the returned signing-key URL with a guessed URL. If the discovered token endpoint differs from `lab.env`, set `VERIFY_TOKEN_URL` to that returned value in `lab.env`.

## 5.2 Run the dedicated-lab bootstrap

```bash
bash vault/scripts/11_bootstrap_agent_subject_lab.sh
```

The script activates OAuth Resource Server, creates `course-verify`, enables KV v2 at `course-tools/`, stores the dummy key at `course-tools/data/premium-enrollment`, writes the ACL and ceiling, and creates an eight-hour sync token. It does not create an agent or human entity.

**Expected:** successful completion and a printed `VAULT_MOUNT_ACCESSOR`. A feature activation 404, invalid license or unsupported API is a blocking compatibility failure. Check that the request reaches the intended Enterprise binary and that the license includes these capabilities.

## 5.3 Record the binding and restricted token

```bash
export VAULT_SYNC_TOKEN="$(cat .uc3-sync-token)"
curl --fail-with-body -sS -H "X-Vault-Token: $VAULT_ADMIN_TOKEN" \
 "$VAULT_ADDR/v1/sys/config/oauth-resource-server/$VAULT_PROFILE" \
 -o .runtime/vault-profile.json
export VAULT_MOUNT_ACCESSOR="$(jq -er '.data.mount_accessor //
 ("oauth-resource-server_root_" + .data.config_id)' .runtime/vault-profile.json)"
printf 'VAULT_MOUNT_ACCESSOR=%s\n' "$VAULT_MOUNT_ACCESSOR"
jq -e --arg issuer "$VERIFY_ISSUER" '.data | .issuer_id==$issuer and .enabled==true and
 .user_claim=="sub" and .optional_authorization_details==false' .runtime/vault-profile.json
```

**Expected:** `true`. Copy the accessor value into your notes for Step 7. The synthesized fallback applies to the root namespace used here. The alias is created with issuer and external ID; Vault derives the matching accessor.

## 5.4 Verify both policies and the restricted credential

```bash
for policy in course-tool-subject course-tool-ceiling; do
 curl --fail-with-body -sS -H "X-Vault-Token: $VAULT_ADMIN_TOKEN" \
  "$VAULT_ADDR/v1/sys/policies/acl/$policy" | jq '.data | {name,policy}'
done
curl --fail-with-body -sS -H "X-Vault-Token: $VAULT_SYNC_TOKEN" \
 "$VAULT_ADDR/v1/auth/token/lookup-self" -o .runtime/sync-token-check.json
jq -e '(.data.policies|index("uc3-sync")!=null) and
 (.data.policies|index("root")==null) and .data.ttl>0' .runtime/sync-token-check.json
```

**Expected:** each policy grants only `read` on `course-tools/data/premium-enrollment`, and the sync-token check prints `true`. Protect `.uc3-sync-token`; it can provision identities even though it cannot read the credential. Its eight-hour lifetime limits the lab session; if it expires, issue a fresh restricted token and re-render/restart the receiver configuration.

**Stop checkpoint:** trust profile enabled, issuer/JWKS correct, policies stored and restricted token valid. Continue to Step 6.


# 6. Create the Verify clients, human and agent

**Purpose:** create every Verify-side identity used by the lab. The required set is one recipe API client and four runtime OAuth applications: Portal, Runtime, Task Exchange and Credential Exchange. Use dedicated lab applications so the trusted AgentID mappings and policy changes cannot affect other applications.

## 6.1 Create the recipe API client

1. Sign in to the IBM Verify administration console as an administrator.
2. Open **Security → API access** and add an API client named **UC3 Recipe API Client**.
3. Enable the authorization-detail administration entitlement (`manageAuthDetailTypes`,`writeAgents`,`manageAgentStatus`,`manageOidcDynamicClient`,`readUsers`) and the API entitlements that allow reading AI agent records in this tenant. The same client is used by Antenna to read the current agent record and authenticate SSF stream requests, following the recipe configuration.
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

Open **Applications → Applications → Add application → OpenID Connect**. Complete mandatory display/owner fields and create each of the following. Select confidential clients with `client_secret_post` (credentials in the form body) for this lab; use **JWT** access tokens signed with RS256. Save each application before recording credentials.

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
- Set nominal access-token lifetime 3,600 seconds for Course Task Exchange and 300 seconds for Course Credential Exchange; the later JWT check shows the actual issued expiry.

Configure the subject mappings and delegation rules for these applications as described in Step 8

**Note**:
Token format: In each application’s token settings, explicitly select JWT as the access-token format and RS256 as the signing algorithm. Do not leave the format as Default.

Entitlements: Open each exchange application’s Entitlements settings and grant access to the human test user—or the test group containing that user—used in this walkthrough. Save the entitlement on both Course Task Exchange and Course Credential Exchange.

**Expected:** four distinct saved OAuth clients and two distinct exchange client credentials. All `*_CLIENT_*` fields in `lab.env` have actual values.

## 6.3 Create and entitle the human test account

In **Users & groups → Users** (or the tenant's user directory), add a dedicated user, **Course Learner**, using an email address you control. Complete account activation/password setup. Open **Course Portal → Entitlements**, grant this user access and save. If the tenant uses an external identity provider, provision/entitle an equivalent test user through that provider.

**Expected:** the user is active, can sign in and is entitled to Course Portal. A second distinct user can be added later to validate identity reuse across humans.

## 6.4 Onboard and activate Course Assistant

1. Open **Identities → AI agents**.
2. Add/onboard **Course Assistant**, description **Assists a human with premium course enrollment**.
3. Assign the responsible human owner and save the record.
4. Open its identity/authentication or OAuth-client associations settings. Associate **Course Assistant Runtime** for the purpose of **`agent_id`**.
5. Complete any approval workflow, then activate it. Do not assume a requested status bypasses approval.
6. Record its generated registry UUID in `VERIFY_AGENT_ID` in `lab.env`.

This is the registry UUID, not the actor client ID. Use the supported association UI; the lab does not POST the read-only `oauthClients` attribute to fabricate an association.

**Expected:** the saved agent shows ACTIVE and exactly one runtime association for purpose of `agent_id`.

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


# 7. Start Antenna and synchronize the agent

**Purpose:** receive a management notification, retrieve the current Verify agent, and provision the corresponding Vault entity, issuer-bound AgentID alias and registration. Synchronization does not copy credentials from Verify or mint runtime tokens.

Verify pushes notifications to the transmitter. The receiver polls the SSF stream and calls Verify/Vault APIs. The same recipe API client credentials are used for Agent API reads and SSF stream authentication.

## 7.1 Authenticate ngrok — Terminal C

```bash
ngrok config add-authtoken '<your-ngrok-authtoken>'
ngrok http https://localhost:9044
```

**Expected:** ngrok prints a public HTTPS forwarding URL. Keep Terminal C running. Copy that URL into `NGROK_URL` in `lab.env`. The transmitter is started below; until then forwarding may show upstream errors.

## 7.2 Load the single lab configuration — Terminal B

The repository root contains `lab.env.example`, alongside `README.md`. You created `lab.env` from it in Step 3 and filled the recipe API client in Step 6. 

```bash
if [ -f ./lab.env ] &&
   [ -d ./sync/antenna/reference-implementation ]; then
  export UC3_ROOT="$PWD"
  source "$UC3_ROOT/lab.env"
  export ANTENNA_ROOT="$UC3_ROOT/sync/antenna/reference-implementation"
  printf 'PASS: ANTENNA_ROOT=%s\n' "$ANTENNA_ROOT"
else
  printf 'STOP: run this from the extracted repository root.\n'
fi
```
**Expected**: both paths include your actual extraction directory and the block prints PASS. If it prints STOP, do not proceed to Step 7.3. An empty UC3_ROOT would expand the derived path to /sync/antenna/reference-implementation; a new terminal does not inherit exports from a previously opened terminal. Re-run this block after opening a new setup terminal.

Ensure `NGROK_URL` in `lab.env` matches the HTTPS URL from Terminal C. The Antenna helpers automatically load the same root `lab.env`, the restricted token from `.uc3-sync-token` and the OAuth binding from `.runtime/vault-profile.json`.

The supplied 26.03.0 compatibility path uses `SUBJECT_FORMAT=opaque` consistently in both handlers. Container access to Vault uses `http://host.docker.internal:8200`. Runtime secret reads still use the Verify credential JWT; Antenna provisioning uses only the restricted Vault token.

**Expected:** the required settings are present in root `lab.env`. Do not create `00_env.local.sh` or paste the Vault root token into the receiver configuration.

## 7.3 Generate and start the components

```bash
cd "$ANTENNA_ROOT"
mkdir -p db-tx db-rx
bash scripts/02_generate_san_certs.sh
bash scripts/03_render_templates.sh
docker compose config --quiet
docker compose pull
docker compose up -d
sleep 60
docker compose ps
docker compose logs --tail=100 antenna-transmitter antenna-receiver
```

**Expected:** both services running, without persistent initialization/configuration errors. Allow partition assignment to become ready; if startup takes longer, inspect logs before proceeding. Do not erase databases to resolve a temporary readiness message.

If container names are already allocated, inspect `docker ps -a --filter name=verify-vault-agent-registry`. Stop only the conflicting dedicated lab or rename its stopped containers. Do not delete unrelated containers. Generate signing keys once; do not regenerate them just to retry delivery.

The local rendered configuration contains secrets and test certificates. Keep it private. Docker must be able to read mounted configuration and write `db-tx`/`db-rx`; the supplied scripts set permissive lab ownership modes for compatibility.

## 7.4 Check local metadata and public routing

```bash
curl --fail-with-body -sk https://localhost:9044/.well-known/ssf-configuration \
 -o "$UC3_ROOT/.runtime/ssf-local.json"
curl --fail-with-body -sS "$NGROK_URL/.well-known/ssf-configuration" \
 -o "$UC3_ROOT/.runtime/ssf-public.json"
jq -e 'type=="object"' "$UC3_ROOT/.runtime/ssf-local.json"
jq -e 'type=="object"' "$UC3_ROOT/.runtime/ssf-public.json"
```

**Expected:** both checks print `true`, and metadata advertises the supplied create/patch SCIM event URIs. `-k` is used only for the self-signed local Antenna listener. A public-only failure indicates ngrok/routing; a local failure indicates startup/configuration.

## 7.5 Create the receiver's SSF stream

```bash
bash scripts/create_scim_stream.sh
docker compose logs --tail=100 antenna-receiver
```

**Expected:** a successful 2xx management response and polling established without persistent OAuth/stream errors. The helper saves `receiver-stream-scim.json` locally and requests both create and patch event types. Create the stream once for this new lab. If authentication fails, verify the recipe API client credentials, the successful token request from Step 6.1 and the discovery URL. Both Antenna components must load the same credentials from lab.env.

## 7.6 Prove the local synchronization path

```bash
export AGENT_ID="$VERIFY_AGENT_ID"
bash scripts/send_test_modification.sh
sleep 60
docker compose logs --tail=150 antenna-transmitter antenna-receiver
cd "$UC3_ROOT"
bash vault/scripts/05_validate_synced_agent.sh
```

**Expected:** successful Verify GET and Vault calls, followed by `PASS` from the synchronization check. The synthetic notification references a real AgentID; the receiver retrieves its actual state from Verify. It does not invent an ACTIVE agent. This proves the local notification→SSF→Vault path, separately from tenant webhook delivery.

The checkpoint requires an enabled `verify-agent-<AgentID>` entity, one matching issuer-bound alias with `name` and `external_id` equal to AgentID, `course-tool-subject` ACL, and registration with `course-tool-ceiling`. A missing alias, mismatched issuer or absent ACL/registration is a blocker.

## 7.7 Configure automatic Verify notifications

1. In the Verify administration console open **Integrations → Notification webhooks**.
2. Open **UC3 Agent Sync** prepared in Step 7.1, or click **Create webhook** and use that name.
3. Set its destination to `<NGROK_URL>/sources/push_src_1/events`.
4. Add `Content-Type: application/json`. Leave payload transformations unset; the mapper expects management-event JSON.
5. Click **Next** to open **Event subscription**. Click **Add custom event** and name it **UC3 Agent Modified**.
6. Under **Interests**, add these property/value pairs, each with operation **Include**:

| Property / key | Value | Operation |
|---|---|---|
| `event_type` | `management` | Include |
| `data.resource` | `ai_agent` | Include |
| `data.action` | `modified` | Include |
| `data.result` | `success` | Include |

7. Click **Add** to save the custom event to the webhook's event subscriptions.
8. Click **Add custom event** again and name it **UC3 Agent Created**. Add the same four Include conditions, changing only `data.action` to **`created`**, then click **Add**.
9. Confirm **both custom events** are listed. Use separate events because conditions inside one custom event are combined with AND; one payload cannot have `data.action` equal to both `modified` and `created`.
10. Click **Create** for a new webhook, or **Save changes** when editing. Test the connection.
11. Change Course Assistant's description in Verify and save a real modification. Open ngrok's local request inspector at `http://localhost:4040/inspect/http` and verify that the management payload reached the destination.

These custom webhook subscriptions select Verify management notifications. The SCIM create/patch event definitions in Antenna's `custom_events.yml` are a separate configuration already rendered in Step 7.3; do not enter their URNs as webhook management-event filters. For the webhook UI and interest matching model, see [Creating a notification webhook](https://www.ibm.com/docs/en/security-verify?topic=interface-creating-notification-webhook).

The modification payload must identify `event_type=management`, `data.resource=ai_agent`, `data.action=modified`, `data.result=success` and `data.id=<AgentID>`. A connection-test body such as `{"test":true}` cannot prove synchronization. UI labels for event selectors vary by tenant release; verify those actual fields in the delivered payload.

The supplied `http_push` lab ingress has no configured webhook authentication. Use it only for this isolated demonstration. If your tenant requires webhook authentication, configure a supported Antenna authenticated ingress and the matching webhook credentials before claiming automatic delivery; SSF stream OAuth does not authenticate the incoming webhook.

```bash
cd "$ANTENNA_ROOT"
docker compose logs --tail=150 antenna-transmitter antenna-receiver
cd "$UC3_ROOT"
bash vault/scripts/05_validate_synced_agent.sh
```

**Expected:** the real tenant event reaches both components and the existing entity is updated, with no duplicate. If the tenant notification does not arrive, stop and fix its subscription/routing. Do not count the local synthetic event as evidence of automatic delivery.

**Stop checkpoint:** local synchronization and actual tenant webhook delivery both pass. Continue to Step 7A.


# 7A. Check the stored credential before token issuance

**Purpose:** prove the secret exists and matches the protected API's configured dummy value. This isolates secret storage from later JWT authorization failures.

Step 5 created the credential. Inspect it without displaying the key:

```bash
cd "$UC3_ROOT"
curl --fail-with-body -sS -H "X-Vault-Token: $VAULT_ADMIN_TOKEN" \
 "$VAULT_ADDR/v1/course-tools/data/premium-enrollment" -o .runtime/admin-secret-check.json
jq -e --arg key "$PREMIUM_API_EXPECTED_KEY" '.data.data.api_key==$key' \
 .runtime/admin-secret-check.json
rm .runtime/admin-secret-check.json
```

**Expected:** `true`. HTTP 404 means the mount or secret was not created; return to Step 5. A key mismatch must be fixed before continuing.

KV v2 has two related paths: CLI path `course-tools/premium-enrollment` and API/ACL/RAR path `course-tools/data/premium-enrollment`. Runtime authorization uses the API path including `/data/`.

**Stop checkpoint:** administrator read and expected-value comparison pass. Continue to Step 8.


# 8. Configure authorization details and delegation rules

**Purpose:** authorize the human-context task and then convert its authority to a narrow agent-subject credential-read JWT. The second exchange uses the task token as `subject_token`, not the original human token. The final `act` is retained.

## 8.1 Register the two authorization detail types

Refresh the setup API token if it has expired by repeating Step 6.1. Then:

```bash
cd "$UC3_ROOT"
bash verify/scripts/05_create_vault_path_access_adt.sh
```

**Expected:** `PASS` for both `vault:path_access` and `urn:ibm:demo:verify:course_credential_task`. The helper builds the create payload from the bundled schema, sends it to `/v1.0/auth-detail-types`, and stores responses privately under `.runtime/`.

A 409 means that type already exists in the tenant. The helper still attempts both types, then stops at a compatibility checkpoint. Inspect each existing schema in the console and confirm it accepts the request below; once confirmed, proceed to the application bindings without recreating the type. Do not overwrite a shared type or rename `vault:path_access` as a workaround. A 401/403 means the setup API token or entitlement needs correction.

In each exchange application's **Sign-on → Authorization details** settings, attach only its type and reject unknown types:

| Application | Allowed type | Requested fields |
|---|---|---|
| Course Task Exchange | `urn:ibm:demo:verify:course_credential_task` | `action=premium_enroll`, `courseId=PREM-801`, unique `reference` |
| Course Credential Exchange | `vault:path_access` | `path=course-tools/data/premium-enrollment`, `capabilities=["read"]` |

If the tenant requires consent/preapproval for either type, complete the user grant through its supported approval workflow. Keep consent controls enabled; an issuance error is not a reason to bypass them.

## 8.2 Bind Runtime and Credential Exchange to the permanent AgentID

For **Course Assistant Runtime**, open **Sign-on → Endpoint configuration → ID token and user info → Edit**. Add a custom rule targeting `sub`. Its value is a quoted string containing the real registry UUID, for example `"<your-actual-AgentID>"`. Save.

Apply the same `sub` rule to **Course Credential Exchange**. Leave Course Portal and Course Task Exchange subjects unchanged. Do not add a rule clearing `act`.

These are administrator-reviewed bindings for this dedicated agent. Never let the caller select the trusted output AgentID. New tokens must be issued after changing mappings.

**Expected contract:** actor token subject = AgentID; task token subject = human; credential token subject and immediate `act.sub` = AgentID. Step 10 checks the actual signed output.

## 8.3 Permit the actor in each incoming subject context

Open **Course Portal → Sign-on → Endpoint configuration → Introspect → Edit**. Add a custom rule targeting `may_act` with this object, replacing both placeholders:

```json
{"sub":"<actual-AgentID>","client_id":"<Course-Assistant-Runtime-client-id>"}
```

Add the same `may_act` rule to **Course Task Exchange**. The first mapping permits the runtime actor against the human's token; the second permits it when the task token becomes the next subject token. Keep default actor validation enabled on both exchange applications.

**Expected:** both rules are saved on the correct applications. `may_act` is subject-token introspection context; it is not an extra form parameter in the exchange request.

## 8.4 Restrict the actual input clients and task

Generate the criteria with your exported IDs:

```bash
python3 - <<'PYRULE'
import os
from pathlib import Path
actor=os.environ['ACTOR_CLIENT_ID']; agent=os.environ['VERIFY_AGENT_ID']
portal=os.environ['WEB_CLIENT_ID']; task=os.environ['TASK_CLIENT_ID']
base=f"requestContext.actor_token.client_id == '{actor}' &&\nrequestContext.actor_token.sub == '{agent}' &&\n"
Path('.runtime/task-actor-criteria.cel').write_text(base+f"requestContext.subject_token.client_id == '{portal}'\n")
Path('.runtime/credential-actor-criteria.cel').write_text(base+f"requestContext.subject_token.client_id == '{task}' &&\n"+
 "has(requestContext.subject_token.authorization_details) &&\n"+
 "requestContext.subject_token.authorization_details.exists(d,\n"+
 " d.type == 'urn:ibm:demo:verify:course_credential_task' &&\n"+
 " d.action == 'premium_enroll' && d.courseId == 'PREM-801')\n")
print('PASS: generated both criteria files')
PYRULE


cat .runtime/task-actor-criteria.cel
cat .runtime/credential-actor-criteria.cel
```

Open **Course Task Exchange → Sign-on → Token exchange → Actor criteria → Set criteria** and paste the task-actor-criteria.cel file. 

Apply the second file to **Course Credential Exchange→ Sign-on → Token exchange → Actor criteria → Set criteria** and paste the credential-actor-criteria file.Save and test it with the console's incoming-token context where available. Do not remove task validation to make an exchange succeed.

The rules restrict this demonstration to PREM-801 and the dedicated client/actor chain. PREM-901 is a deliberate disallowed premium course. Business eligibility, real purchase authorization and payment approval require trusted business rules in a production task service/API; this sample does not implement those services or CIBA.

**Stop checkpoint:** two types registered and bound, correct subject mappings saved, both `may_act` rules and restrictive Actor Criteria saved. Continue to Step 9.


# 9. Prepare application configuration and test dependencies

**Purpose:** build the portal environment from the settings already collected and validate the local application before interactive use.

```bash
cd "$UC3_ROOT"
source lab.env
python3 scripts/03_write_app_env.py
cd app
npm ci
npm run check
npm test
cd "$UC3_ROOT"
node sync/antenna/reference-implementation/tests/test_handlers.cjs
python3 verify/tests/test_exchange_helper.py
```

**Expected:** the configuration helper prints `PASS`, dependency installation completes, JavaScript syntax checks pass, portal/API/exchange tests pass, and all synchronization checks pass. The portal file contains runtime client credentials only; it excludes the Vault administrator token, synchronization token and Verify setup client credentials.

If npm cannot reach the package registry, correct the workstation's network/proxy/registry settings and retry `npm ci`. Do not assume dependencies were installed after a failed command. If any test fails, resolve it before proceeding.

No server is started in this step. Port 4000 is used temporarily by the sign-in helper in Step 10 and then by the portal in Step 11.

**Stop checkpoint:** `app/.env` exists, dependency installation and local tests pass. Continue to Step 10.


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


# 11. Run the Course Portal demonstration

**Purpose:** exercise the complete application after the individual remote boundaries have passed.

## 11.1 Start the portal — Terminal D

Open a terminal, navigate to the extracted `agent-identity-vault-course-agent-sample-main` directory and run:

```bash
cd app
npm start
```

**Expected:** `Course demo listening at http://localhost:4000`. The Step 10 sign-in helper must already have exited. Keep Terminal D running. The server loads the `app/.env` generated in Step 9.

## 11.2 Sign in and validate the standard path

1. Open `http://localhost:4000` in the browser.
2. Choose sign in and authenticate as Course Learner.
3. Enroll in **BAS-101 — Security Fundamentals**.

**Expected:** enrollment succeeds and appears in My enrollments. The trace indicates no Vault credential was required for this standard course.

## 11.3 Validate premium enrollment

Choose **PREM-801 — Enterprise AI Agent Security** and enroll.

**Expected:** the trace shows actor authentication, task token exchange, credential token exchange, Vault credential read and protected Course API HTTP 200. The course appears in My enrollments. Credential values are redacted.

The app obtains fresh actor/task/credential tokens for each premium request. The human access token comes from the current sign-in session. If it expires, sign out and sign in again.

## 11.4 Confirm the policy boundary

Choose **PREM-901 — Advanced Agent Governance** and enroll.

**Expected:** the operation is denied before the protected API completes because this lab's allowed task schema/criteria is restricted to PREM-801. No PREM-901 enrollment should appear. This is an intentional authorization test, not a storage failure.

The downstream API is a demonstration API-key consumer. It does not validate the task JWT or process an actual payment. Enrollments are stored in the browser's server-side session and reset when that session/app state is cleared.

**Stop checkpoint:** BAS-101 and PREM-801 succeed, PREM-901 is denied. Continue to Step 12 for lifecycle and negative tests.


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


# 13. Troubleshooting, restart and cleanup

| Symptom | Check | Required recovery |
|---|---|---|
| Vault activation 404 or unsupported API | Actual Enterprise binary, URL and license capabilities | Correct the product/build/license before proceeding |
| License failure at startup | Absolute `VAULT_LICENSE_PATH`, license validity and binary | Restart the disposable server only after correcting the license; repeat setup after its state loss |
| Agent GET 401/403 | Recipe API client, management endpoint, entitlement | Refresh the management token or correct rights; do not substitute an OAuth actor token |
| Agent GET 404/400/406 | Actual registry ID, API path, Accept header | Use the verified Agent path and `application/scim+json` |
| ACTIVE agent not provisioned | API response's `oauthClients[].purposes` | Save the real `agent_id` association; missing purpose is not inferred |
| Metadata local failure | Container logs, rendered YAML/custom event catalogue, startup readiness | Correct the local service before retrying public routing |
| Metadata public-only failure | ngrok URL and upstream scheme/port | Update the configured public URL, re-render and restart if the tunnel URL changed |
| Receiver OAuth error | Recipe API client credentials and discovery URL | Repeat the Step 6.1 token check and verify lab.env was saved |
| Container cannot reach Vault | `host.docker.internal`, Docker host-gateway route, listener and firewall | Verify receiver call results; host-side health alone is insufficient |
| Event arrives but no action | Management event fields, supported event type, real AgentID | Inspect actual payload and Verify GET; a webhook test body is insufficient |
| Actor subject is client ID | Runtime `sub` mapping and fresh token | Apply the trusted AgentID mapping and reissue |
| Credential subject is human | Credential Exchange `sub` mapping | Apply mapping to that application; retain Task Exchange's human subject |
| Exchange denied | Correct clients, RAR binding, `may_act`, Actor Criteria and valid input tokens | Inspect the actual non-2xx error; do not remove validation |
| Registration lookup HTTP 400: agent for provided entity id does not exist | Entity exists but has no registration | Reconcile using the receiver; this exact response is treated as a missing record |
| Vault 403 with current JWT | Issuer/alias, entity ACL, enabled state, registration ceiling, exact RAR | Fix the mismatched component; keep generated `act` |
| Course API 403 after Vault 200 | Stored key versus `PREMIUM_API_EXPECTED_KEY` | Restore matching dummy key |
| Local npm install fails | Network/proxy/registry configuration | Retry `npm ci` only after fixing access |

## Resume a terminal

In a new setup terminal, enter the extracted root and restore exported configuration:

```bash
export UC3_ROOT="$PWD"
source lab.env
export VERIFY_JWKS_URI="$(jq -er '.jwks_uri' .runtime/verify-discovery.json)"
export VAULT_SYNC_TOKEN="$(cat .uc3-sync-token)"
export ANTENNA_ROOT="$UC3_ROOT/sync/antenna/reference-implementation"
```

Check Vault health and synchronize checkpoint before running the app. Restart the app with `npm start` from `app/`. Restart an existing Antenna lab with `docker compose up -d` from its reference-implementation directory; keep its databases, certificates and stream. Do not create a duplicate stream on every retry.

If the eight-hour synchronization token expires, use the admin credential to issue a new token with policy `uc3-sync`, store it privately in `.uc3-sync-token`, export `VAULT_SYNC_TOKEN`, re-render and recreate the receiver container. Its permissions must remain restricted; do not replace it with root to resolve expiry. Run the following from the repository root:

```bash
bash vault/scripts/04_create_sync_token.sh
export VAULT_SYNC_TOKEN="$(cat .uc3-sync-token)"
cd "$ANTENNA_ROOT"
bash scripts/03_render_templates.sh
docker compose up -d --force-recreate antenna-receiver
cd "$UC3_ROOT"
```


## Cleanup

Stop the portal with Ctrl-C in Terminal D. In Terminal B:

```bash
cd "$ANTENNA_ROOT"
docker compose down
```

Stop ngrok with Ctrl-C in Terminal C. Disable the dedicated UC3 webhook in Verify so it no longer sends to an inactive/public tunnel. Stop Vault with Ctrl-C in Terminal A only when you no longer need this disposable server; doing so discards its state. Preserve local files only for as long as needed and keep them private. Remove dedicated lab applications/API clients/agent through their supported lifecycle controls when the lab is retired; leave unrelated objects unchanged.
