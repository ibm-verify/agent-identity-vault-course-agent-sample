<!--
Copyright IBM Corp. All Rights Reserved.

SPDX-License-Identifier: Apache-2.0
-->

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

The repository root contains `lab.env.example`, alongside `README.md`. You created `lab.env` from it in Step 3 and filled the recipe API client in Step 6. **There is no separate SSF client to create and no second credential file to edit.**

```bash
cd "$UC3_ROOT"
source lab.env
export ANTENNA_ROOT="$UC3_ROOT/sync/antenna/reference-implementation"
```

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
sleep 5
docker compose logs --tail=150 antenna-transmitter antenna-receiver
cd "$UC3_ROOT"
bash vault/scripts/05_validate_synced_agent.sh
```

**Expected:** successful Verify GET and Vault calls, followed by `PASS` from the synchronization check. The synthetic notification references a real AgentID; the receiver retrieves its actual state from Verify. It does not invent an ACTIVE agent. This proves the local notification→SSF→Vault path, separately from tenant webhook delivery.

The checkpoint requires an enabled `verify-agent-<AgentID>` entity, one matching issuer-bound alias with `name` and `external_id` equal to AgentID, `course-tool-subject` ACL, and registration with `course-tool-ceiling`. A missing alias, mismatched issuer or absent ACL/registration is a blocker.

## 7.7 Configure automatic Verify notifications

1. In the Verify administration console open **Integrations → Notification webhooks**.
2. Add a dedicated webhook named **UC3 Agent Sync**.
3. Set its destination to `<NGROK_URL>/sources/push_src_1/events`.
4. Add `Content-Type: application/json`. Leave payload transformations unset; the mapper expects the management-event JSON.
5. Subscribe it to successful AI agent creation and modification management events, using the tenant's event-selection controls.
6. Save and test the connection. Then change Course Assistant's description and save a real modification.
7. Open ngrok's local request inspector at `http://localhost:4040/inspect/http` and verify that the real management payload reached the destination.

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
