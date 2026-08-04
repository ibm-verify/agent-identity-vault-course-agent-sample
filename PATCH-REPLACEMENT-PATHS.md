# Corrected OAuth Alias Files — Replacement Paths

Replace these files in your existing cookbook, preserving the same relative paths from the cookbook root:

```text
vault/scripts/10_create_subject_identity.sh
sync/antenna/reference-implementation/scripts/00_env.sh
sync/antenna/reference-implementation/configs/receiver/configs/js/vault_agent_registry_action.js.template
sync/antenna/README.md
sync/custom-adapter/API-RECIPE.md
sync/custom-adapter/INTEGRATION-CONTRACT.md
docs/07-SYNC-AGENT-TO-VAULT.md
docs/10-SMOKE-TEST.md
docs/13-TROUBLESHOOTING.md
docs/13A-VALIDATED-SETUP-TROUBLESHOOTING.md
docs/VALUES-WORKSHEET.md
```

After replacement, preserve your real local values in:

```text
sync/antenna/reference-implementation/scripts/00_env.local.sh
```

Add or confirm:

```bash
export VERIFY_ISSUER="https://<your-tenant>/oauth2"
```

Then regenerate the deployed Antenna configuration and restart the receiver:

```bash
cd sync/antenna/reference-implementation
source scripts/00_env.local.sh
bash scripts/03_render_templates.sh
grep -n 'verifyIssuer\|external_id\|issuer:' deploying/receiver/configs/js/vault_agent_registry_action.js
docker compose restart antenna-receiver
```

Do not replace `00_env.local.sh` with the template, because it contains your environment-specific values.
