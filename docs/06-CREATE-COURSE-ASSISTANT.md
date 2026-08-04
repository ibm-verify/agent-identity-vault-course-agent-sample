# 6. Create the Course Assistant in IBM Verify

This phase creates the agent's **governance identity** and its **runtime OAuth identity**.

## Prerequisite

Vault foundation is ready because synchronization in the next phase needs the Vault OAuth profile/mount binding and ceiling policy.

## Step 6.1 — Create the agent

Note: Refer to onboarding/creating the Agents tutorial for detailed step

In IBM Verify Admin Console, navigate to the Agent/Agent Registry management area and create:

```text
Display name: Course Assistant
Description: Assists users with course discovery and enrollment
Status: ACTIVE
Owner: <your owner/team>
Tags: course, demo
```

Record the generated:

```text
VERIFY_AGENT_ID
```


## Step 6.2 — Create the actor OIDC application

Create a separate OpenID Connect application:

```text
Name: Course Assistant Runtime
Grant type: Client Credentials
Access token format: JWT
```

Record:

```text
ACTOR_CLIENT_ID
ACTOR_CLIENT_SECRET
```



## Step 6.3 — Associate the OAuth client with the Course Assistant

Associate the runtime OIDC client with the Course Assistant agent.

Where the Verify Agent Registry model exposes OAuth-client purposes, use the runtime identity / `agent_id` purpose for the client used to represent the agent.

### Why this matters

```text
Course Assistant Agent
        ↓ associated with
Course Assistant Runtime OIDC Client
        ↓ client_credentials
Actor Access Token
```

The actor in token exchange is determined by the **actor token**. It is not a free-form actor name entered during token exchange.



## Step 6.4 — Obtain one actor token now

Do this before synchronization so you know the runtime identity value that Vault must resolve.

```bash
export VERIFY_TOKEN_URL="https://<tenant>/oauth2/token"
export ACTOR_CLIENT_ID="<client-id>"
export ACTOR_CLIENT_SECRET="<client-secret>"

bash verify/scripts/01_get_actor_token.sh
```

Decode the token:

```bash
bash verify/scripts/02_decode_jwt.sh "$ACTOR_TOKEN"
```

Record:

```text
ACTOR_TOKEN.sub
ACTOR_TOKEN.client_id
ACTOR_TOKEN.iss
```

### Important identity note

The Antenna reference mapper normally uses the associated OAuth client ID as the runtime alias. Confirm that this matches the actor identity expected from your token. If `ACTOR_TOKEN.sub` is different, update the sync mapping so the Vault OAuth alias resolves the actual actor identity.

## STOP CHECKPOINT

```text
[ ] Course Assistant exists in IBM Verify
[ ] VERIFY_AGENT_ID recorded
[ ] Status = ACTIVE
[ ] Actor OIDC client created
[ ] Actor client is associated with the agent
[ ] Actor JWT can be obtained
[ ] Actor JWT sub/client_id recorded
```
