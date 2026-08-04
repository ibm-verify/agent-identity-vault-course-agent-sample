# Vault Assets

Use these files in cookbook order.

- `config/` — OAuth Resource Server profile template trusting IBM Verify.
- `policies/` — human subject baseline policy, agent ceiling policy, and restricted synchronization policy.
- `scripts/00_check_compatibility.sh` — mandatory gate for environments that might be PKI-only.
- `scripts/01...10` — bootstrap, profile binding, agent validation, KV secret, delegated-JWT read, and human identity setup.

Credential separation:

```text
Bootstrap admin/root          -> initial configuration only
Restricted VAULT_SYNC_TOKEN  -> agent synchronization only
IBM Verify delegated JWT     -> runtime secret access
```
