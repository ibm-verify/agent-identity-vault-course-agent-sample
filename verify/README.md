# IBM Verify Assets

Use these files while following `docs/08-CONFIGURE-VERIFY-OBO.md` and `docs/10-SMOKE-TEST.md`.

- `adt/` — current `vault:path_access` Authorization Detail Type schema and creation payload.
- `examples/` — exact RAR used by the premium-course secret read.
- `scripts/` — helper scripts to obtain the actor token, decode JWTs, perform token exchange, and create the ADT through the management API.

The token-exchange client in this cookbook is a dedicated IBM Verify **OIDC application with the Token Exchange grant** and audience `vault-course-tools`.
