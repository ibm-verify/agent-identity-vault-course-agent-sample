# 8. Configure IBM Verify OBO and Token Exchange

This phase creates the human subject application, the delegation relationship, the Vault RAR type, and the OIDC application that performs RFC 8693 token exchange.

Note: For detailed step , Please refer to OBO Token exchange tutorial.

## Why use an OIDC application for token exchange?

This cookbook uses an **OpenID Connect application with the Token Exchange grant**. The OIDC application can also configure the JWT access-token **Audiences** field. That audience is included in the `aud` claim and is matched by the Vault OAuth Resource Server profile.

Recommended audience:

```text
vault-course-tools
```

## Prerequisites

- Course Assistant synchronized to Vault.
- [07A-STORE-TOOL-SECRET-BEFORE-VERIFY.md](07A-STORE-TOOL-SECRET-BEFORE-VERIFY.md) passed with the new non-PKI license.
- `course-tools/premium-enrollment` exists and contains the `api_key` field.
- Actor client ID and actor token identity are known.
- Vault OAuth profile expects audience `vault-course-tools`.

## Step 8.1 — Create the Course Portal subject application

Create an OIDC application:

```text
Name: Course Portal
Grant type: Authorization Code
Response type: code
Redirect URI: http://localhost:4000/callback
Require PKCE verification: enabled
Access token format: JWT
```

Record:

```text
SUBJECT_CLIENT_ID
SUBJECT_CLIENT_SECRET
```

## Step 8.2 — Configure `may_act`

The default delegation validation uses `may_act` to correlate the allowed actor with claims in the actor token.

For the tested client-based mapping:

```json
{
  "client_id": "<ACTOR_CLIENT_ID>"
}
```

Configure this on the **Subject OIDC application** under the Introspect/endpoint mapping area, targeting:

```text
may_act
```


### Mental model

```text
actor_token = Who is actually acting?
may_act     = Is that actor allowed to act for this subject?
```

Leave default actor validation enabled for the base demo. Do not select "Skip default actor validation" unless you intentionally replace `may_act` with a tested Actor Criteria rule.

## Step 8.3 — Create the `vault:path_access` Authorization Detail Type

IBM Verify must validate the same RAR structure that Vault expects. **This is the only Authorization Detail Type required for the base API-key use case.** The downstream course operation remains application logic; the delegated JWT sent to Vault carries only the Vault access constraint required for this secret read.

Use the files:

```text
verify/adt/vault-path-access.schema.json
verify/adt/vault-path-access.create-payload.json
```

Core schema:

```json
{
  "type": "object",
  "required": ["type", "path", "capabilities"],
  "additionalProperties": false,
  "properties": {
    "type": { "const": "vault:path_access" },
    "path": {
      "type": "string",
      "pattern": "^[A-Za-z0-9._/:-]+$"
    },
    "capabilities": {
      "type": "array",
      "uniqueItems": true,
      "items": {
        "type": "string",
        "enum": [
          "read", "create", "update", "delete", "list", "sudo",
          "patch", "subscribe", "recover", "deny"
        ]
      }
    }
  }
}
```

For this use case, the runtime authorization detail is:

```json
[
  {
    "type": "vault:path_access",
    "path": "course-tools/data/premium-enrollment",
    "capabilities": ["read"]
  }
]
```


## Step 8.4 — Create the Token Exchange OIDC application

Create another OpenID Connect application:

```text
Name: Course Vault Token Exchange
Grant type: Token Exchange
Client type: confidential
Access token format: JWT
Audiences: vault-course-tools
```

Token Exchange settings:

```text
Subject Token: Access Token
Actor Token: Access Token
Requested Token: Access Token
Require Actor Token: enabled
Skip default actor validation: disabled
```

Authorization details:

```text
Restrict authorization details: enabled
Ignore unknown authorization details: disabled
Allowed type: vault:path_access
```


Record:

```text
TOKEN_EXCHANGE_CLIENT_ID
TOKEN_EXCHANGE_CLIENT_SECRET
```


## Step 8.5 — Why the audience matters

IBM Verify OIDC Token Settings:

```text
Audiences = vault-course-tools
```

Delegated access token:

```json
{
  "aud": ["vault-course-tools"]
}
```

Vault OAuth Resource Server profile:

```json
{
  "audiences": ["vault-course-tools"]
}
```

If the audience does not match, Vault should reject the JWT.

## STOP CHECKPOINT

```text
[ ] Subject OIDC app created with Auth Code + PKCE + JWT
[ ] may_act maps to the Course Assistant actor identity
[ ] vault:path_access ADT exists
[ ] Token Exchange OIDC app created
[ ] Require actor token enabled
[ ] JWT access token format selected
[ ] Audience vault-course-tools configured
[ ] vault:path_access is the allowed authorization detail type
```
