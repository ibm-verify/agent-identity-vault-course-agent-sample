# 10. Smoke-Test Tokens and Vault Before Running the Course Portal

Do not start the UI until this phase works. This isolates IBM Verify/Vault configuration from application code.

## Step 10.1 — Get actor token

```bash
source verify/scripts/00_env.example.sh   # copy/edit as 00_env.sh first
bash verify/scripts/01_get_actor_token.sh
```

Decode:

```bash
bash verify/scripts/02_decode_jwt.sh "$ACTOR_TOKEN"
```

Check:

```text
client_id = Course Assistant Runtime client
sub       = actor runtime identity
iss       = your Verify issuer
```


## Step 10.2 — Get subject token

Use Authorization Code + PKCE from the Course Portal application or Postman/browser helper.

The Postman collection contains a documentation request describing the Authorization Code flow; the runnable app performs this flow automatically.

Decode the subject access token and verify:

```text
sub     = human user
may_act = correlates with Course Assistant actor token
```

## Step 10.3 — Create the human subject identity in Vault

Agent synchronization covers the Course Assistant, not the human test user. For this demo, create the human Vault Identity entity once after you know the subject token `sub`.

```bash
export SUBJECT_TOKEN_SUB="<value-of-sub-from-subject-token>"
export VERIFY_ISSUER="https://<tenant>/oauth2"
export VAULT_TOKEN="<bootstrap-admin-token>"
source vault/.oauth-runtime.env
bash vault/scripts/10_create_subject_identity.sh
```

This creates/updates:

```text
Human subject Vault Identity entity
+ OAuth alias with name/external_id matching SUBJECT_TOKEN.sub
+ OAuth alias issuer matching delegated JWT iss
+ course-tool-subject baseline policy
```

Vault does not permit adding/changing alias `issuer` after creation. If an older alias has empty `issuer` or `external_id`, follow the delete-and-recreate repair in [13A-VALIDATED-SETUP-TROUBLESHOOTING.md](13A-VALIDATED-SETUP-TROUBLESHOOTING.md).


## Step 10.4 — Perform RFC 8693 token exchange

Use:

```bash
export SUBJECT_TOKEN="<subject-access-token>"
export ACTOR_TOKEN="<actor-access-token>"

bash verify/scripts/03_exchange_obo_token.sh
```

The request includes:

```text
grant_type = urn:ietf:params:oauth:grant-type:token-exchange
subject_token
subject_token_type = access_token
actor_token
actor_token_type = access_token
requested_token_type = access_token
authorization_details = [{vault:path_access ...}]
```

The client authenticating this request is the **Course Vault Token Exchange OIDC application**.


## Step 10.5 — Decode delegated JWT

```bash
bash verify/scripts/02_decode_jwt.sh "$DELEGATED_TOKEN"
```

Verify:

```text
[ ] sub identifies human subject
[ ] actor context identifies Course Assistant
[ ] aud contains vault-course-tools
[ ] authorization_details contains exact path course-tools/data/premium-enrollment
[ ] capabilities contains read
```

Do not continue if these are wrong.

## Step 10.6 — Read Vault secret using the delegated JWT directly

```bash
export DELEGATED_TOKEN="<token>"
bash vault/scripts/08_read_secret_with_delegated_jwt.sh
```

Conceptually:

```http
GET /v1/course-tools/data/premium-enrollment
X-Vault-Token: <IBM_VERIFY_DELEGATED_JWT>
```

Vault should evaluate:

- Verify issuer/JWKS,
- audience,
- subject identity and baseline policy,
- actor identity,
- actor Agent Registry registration,
- actor ceiling policy,
- RAR exact path/capability.


## STOP CHECKPOINT

```text
[ ] Actor token works
[ ] Subject token works
[ ] may_act validation succeeds
[ ] Token exchange returns delegated JWT
[ ] delegated aud matches Vault audience
[ ] delegated authorization_details are correct
[ ] Vault accepts delegated JWT
[ ] Vault returns the api_key field
```

Only now start the Course Portal.
