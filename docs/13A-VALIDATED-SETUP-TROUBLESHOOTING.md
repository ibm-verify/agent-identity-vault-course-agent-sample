# 13A. Validated Mac, Vault, Alias, and Antenna Troubleshooting

This document records the setup failures encountered during the validated macOS/Colima run and the checks that distinguished harmless messages from real blockers.

## 1. `vault: command not found`

Cause: the Vault binary was downloaded but its directory was not in `PATH`.

```bash
export PATH="$HOME/Downloads/vault_2.0.3+ent_darwin_arm64:$PATH"
which vault
vault version
```

Persist the export in your shell profile only after confirming the absolute directory is correct.

## 2. `VERIFY_ISSUER` is blank although it appears in a JSON template

A JSON value does not create a shell variable. Export it before running the profile script:

```bash
export VERIFY_ISSUER="https://<tenant>/oauth2"
echo "$VERIFY_ISSUER"
bash vault/scripts/01_configure_oauth_resource_server.sh
```

There is no need to rename or execute the JSON template.

## 3. OAuth profile succeeds, then the JSON template reports `Permission denied`

If Vault already returned an enabled `course-verify` profile, the API write succeeded. The permission error means a local script line tried to execute the `.json.template` file.

Do not make the JSON executable. Compare your local script with the packaged version:

```bash
nl -ba vault/scripts/01_configure_oauth_resource_server.sh | sed -n '1,40p'
```

The template must appear only as input to `sed`; the final commands should be:

```bash
vault write "sys/config/oauth-resource-server/$VAULT_OAUTH_PROFILE" @"$TMP"
rm -f "$TMP"
vault read "sys/config/oauth-resource-server/$VAULT_OAUTH_PROFILE"
```

Then obtain the binding:

```bash
bash vault/scripts/02_get_oauth_profile_binding.sh
```

## 4. Do not confuse `config_id` with `mount_accessor`

Example:

```text
config_id:      47ef5b3e-08ff-7d8a-1b1b-5b0f42d6f76c
mount_accessor: oauth-resource-server_root_47ef5b3e-08ff-7d8a-1b1b-5b0f42d6f76c
```

The alias requires the full accessor beginning with `oauth-resource-server_`; an `auth_token_...` accessor and the bare UUID are incorrect.

## 5. `docker exec ... printenv VAULT_MOUNT_ACCESSOR` is blank

In this reference implementation that is expected. `VAULT_MOUNT_ACCESSOR` is not a receiver-container environment variable. It is substituted into:

```text
deploying/receiver/configs/js/vault_agent_registry_action.js
```

Check the rendered file:

```bash
grep -n 'var mountAccessor' \
  deploying/receiver/configs/js/vault_agent_registry_action.js
```

If it shows `var mountAccessor = "";`, load the local environment and rerender:

```bash
source scripts/00_env.local.sh
echo "$VAULT_MOUNT_ACCESSOR"
bash scripts/03_render_templates.sh
```

Expected:

```javascript
var mountAccessor = "oauth-resource-server_root_<config-id>";
```

Check that no Vault placeholders remain:

```bash
grep -n '\${VAULT_' deploying/receiver/configs/js/vault_agent_registry_action.js
```

No output is expected. Restart the receiver after rerendering:

```bash
docker compose restart antenna-receiver
```

## 6. Changing `00_env.local.sh` does not change the running action

Editing the environment file alone is insufficient. The required sequence is:

```bash
source scripts/00_env.local.sh
bash scripts/03_render_templates.sh
grep -n 'var mountAccessor' deploying/receiver/configs/js/vault_agent_registry_action.js
docker compose restart antenna-receiver
```

Do not repeatedly recreate the container without rerendering the mounted JavaScript.

## 7. `no such service: receiver`

The Compose service name is `antenna-receiver`; the container name is `verify-vault-agent-registry-receiver`.

```bash
docker compose config --services
docker compose up -d --force-recreate antenna-receiver
docker logs -f verify-vault-agent-registry-receiver
```

Use service names with `docker compose`; use container names with `docker exec` and `docker logs`.

## 8. `partitioner not ready` during receiver startup

This can be transient. Wait for messages similar to:

```text
is ready. New instanceID [0]
Finished processing poll StreamID
```

If readiness appears, the earlier partitioner messages are not the alias failure. If readiness never appears, inspect storage mounts, stream configuration, and receiver logs before sending another event.

## 9. Apple Silicon image platform warning

On an ARM64 Mac, Antenna 26.03 can report that a `linux/amd64` image does not match `linux/arm64/v8`. If the container remains `Up` and reaches receiver readiness, this is a compatibility/performance warning rather than the immediate failure.

```bash
docker ps
docker logs verify-vault-agent-registry-receiver --since 5m
```

Do not treat the warning as success by itself; require the readiness log.

## 10. Docker API socket missing on macOS

For the Colima setup:

```bash
colima start
docker context use colima
unset DOCKER_HOST
docker info
```

Do not start Antenna until `docker info` succeeds.

## 11. Alias still fails after the correct accessor is rendered

Check the actual actor token identity and alias record:

```bash
vault list identity/entity-alias/id
vault read identity/entity-alias/id/<ALIAS_ID>
```

Validate all three values:

```text
alias name      = identity used by the actor JWT/profile user_claim
mount_accessor  = oauth-resource-server_root_<config-id>
canonical_id    = synchronized Course Assistant Vault entity ID
```

Then trigger a new harmless Verify agent update and search recent receiver logs:

```bash
docker logs verify-vault-agent-registry-receiver --since 10m 2>&1 \
  | grep -Ei -C 5 'alias|mount_accessor|canonical|400|403|error|fail'
```

## 12. New license installed but KV v2 is still rejected

First confirm the active license and the running Vault process:

```bash
vault read sys/license/status
vault status
bash vault/scripts/00_check_compatibility.sh
```

Common causes are: the new license was not loaded by the running process, an old Vault process is still serving port 8200, a namespace is wrong, or the bootstrap token cannot manage mounts. Do not proceed to Guide 8 until the compatibility gate reports `PASS: KV v2 secret engine is permitted`.

## 13. Safe final checkpoint before Guide 8

```bash
bash vault/scripts/00_check_compatibility.sh
bash vault/scripts/06_enable_kv.sh
bash vault/scripts/07_store_matching_tool_secret.sh
test "$(vault kv get -field=api_key course-tools/premium-enrollment)" = \
  "course-premium-demo-key-2026" && echo PASS || echo FAIL
```

Continue to `08-CONFIGURE-VERIFY-OBO.md` only when this prints `PASS` and the synchronized alias/Agent Registry record still exists.

## 14. Token exchange succeeds but Vault audit shows `auth.entity_id=null`

Validated cause: subject and/or actor aliases were created with `name`, `canonical_id`, and `mount_accessor`, but empty `issuer` and `external_id`. The alias exists yet cannot bind an OAuth JWT to the entity.

Inspect an alias:

```bash
vault read -format=json identity/entity-alias/id/<ALIAS_ID> |
jq '.data | {id,name,external_id,issuer,canonical_id,mount_accessor}'
```

Required creation payload:

```text
name          = JWT identity value
external_id   = subject sub or actor act.sub
issuer        = exact JWT iss
canonical_id  = intended Vault entity
mount_accessor= OAuth Resource Server profile accessor
```

Vault returns `changes to issuer after alias creation are prohibited` if you try to patch an incomplete alias. Back up and delete only the alias, then recreate it on the same canonical entity with all five fields. The entity, policies, Agent Registry registration, and secrets remain intact.

Do not work around this condition by changing clock skew, broadening audiences, disabling RAR, removing default ceilings, or attaching the ceiling policy directly to the actor entity.
