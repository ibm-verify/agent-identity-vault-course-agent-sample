# Screenshot Checklist

The repository includes two kinds of images:

1. **Reference screenshots** copied from the supplied setup document where the configuration area is still useful.
2. **Placeholders** for tenant/build-specific screens that should be replaced during final documentation capture.

Replace a placeholder by keeping the same filename so all Markdown links continue to work.

| File | Capture |
|---|---|
| `01-verify-create-agent.png` | Create Course Assistant Agent screen + generated Agent ID |
| `02-verify-associate-oauth-client.png` | Agent → associated OAuth client/runtime identity |
| `03-verify-actor-oidc-client.png` | Actor OIDC Client Credentials + JWT settings |
| `04-vault-oauth-resource-profile.png` | OAuth profile issuer/JWKS/audience/config_id |
| `05-vault-agent-after-sync.png` | Vault Agent Registry record + ceiling policy |
| `06-verify-subject-app.png` | Course Portal Auth Code + PKCE + JWT |
| `07-verify-token-exchange-app.png` | OIDC Token Exchange settings + audience |
| `08-verify-adt.png` | `vault:path_access` ADT schema |
| `09-postman-token-exchange.png` | Postman token exchange success |
| `10-vault-secret-read.png` | Delegated JWT successfully reading secret |
| `11-premium-success.png` | Premium enrollment success |
| `12-premium-denied-agent.png` | Vault denial when agent registration missing |
| `13-premium-denied-wrong-key.png` | Tool HTTP 403 with wrong Vault secret |
| `14-antenna-ngrok.png` | Antenna services + ngrok + discovery URL |
| `15-verify-may-act.png` | Course Portal `may_act` mapping for the Course Assistant actor |
| `16-vault-subject-identity-alias.png` | Human subject entity + baseline policy + OAuth alias |
| `17-vault-agent-identity-alias.png` | Synchronized Course Assistant entity + runtime OAuth alias |
| `18-vault-tool-secret.png` | KV path/key name with API-key value redacted |
| `19-verify-adt-assignment.png` | `vault:path_access` allowed on the Token Exchange OIDC application |
| `20-postman-actor-token.png` | Actor token HTTP 200 + safe decoded claims |

Never capture real client secrets, access tokens, root tokens, synchronization tokens, or production API keys in screenshots.
