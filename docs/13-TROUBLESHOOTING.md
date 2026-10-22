<!--
Copyright IBM Corp. All Rights Reserved.

SPDX-License-Identifier: Apache-2.0
-->

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
