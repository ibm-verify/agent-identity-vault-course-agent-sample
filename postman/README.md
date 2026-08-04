# Postman Walkthrough(Just for reference)

Import:

1. `IBM-Verify-Vault-Course-Agent.postman_collection.json`
2. `Course-Agent-Local.postman_environment.json`

## Before running

Complete the cookbook through agent synchronization and IBM Verify OBO configuration. Fill the environment variables and keep real secrets/tokens out of Git.

## Execution order

### 1. Verify discovery and Vault health

Run the two requests in **00 - Read First**.

### 2. Get Course Assistant Actor Token

Runs Client Credentials against the Actor OIDC application and saves `actor_token`.

Review only the safe decoded claims and confirm `sub`/`client_id` matches the runtime identity synchronized to the Vault alias.

### 3. Obtain the human subject token

Open **02 - IBM Verify Subject → Subject Token Setup Guide — Authorization Code + PKCE**.

Two supported testing paths are documented:

- use the Course Portal browser login and paste the resulting access token into `subject_token`, or
- use Postman's OAuth 2.0 helper with PKCE after adding Postman's callback URI to the Subject OIDC application.

Verify the subject token contains the expected human `sub` and the configured `may_act` relationship before continuing.

### 4. Exchange Subject + Actor for Delegated JWT

Uses the **Course Vault Token Exchange OIDC application**.

Request includes:

```json
[
  {
    "type": "vault:path_access",
    "path": "course-tools/data/premium-enrollment",
    "capabilities": ["read"]
  }
]
```

The test saves `delegated_token` and checks that `aud` includes `vault-course-tools`.

### 5. Read Course Assistant Agent Registry Record

Administrative validation using `vault_sync_token`. Confirms the actor entity is registered. This is not a runtime credential.

### 6. Read Premium Tool API Key with Delegated JWT

Runtime request using:

```http
X-Vault-Token: {{delegated_token}}
```

The test stores the returned `api_key` in `vault_api_key` without logging its value.

### 7. Call Premium Enrollment Tool

Passes:

```http
X-Course-API-Key: {{vault_api_key}}
```

Expected HTTP 200 with the matching secret.

For the wrong-key negative test, change the Vault secret with `vault/scripts/09_store_invalid_tool_secret.sh`, rerun the Vault secret read and protected-tool requests, and expect HTTP 403 from the tool.
