# 11. Run the Course Portal Demo

## Prerequisites

The smoke test in [10-SMOKE-TEST.md](10-SMOKE-TEST.md) must pass.

## Step 11.1 — Configure the application

```bash
cd app
cp .env.example .env
```

Fill in:

- Verify issuer/token endpoint.
- Subject client credentials.
- Actor client credentials.
- Token Exchange OIDC client credentials.
- Vault address and secret path.
- Expected Premium Tool API key.

## Step 11.2 — Install and start

```bash
npm ci
npm test
npm start
```

Open:

```text
http://localhost:4000
```

## Step 11.3 — Sign in

The app performs Authorization Code + PKCE using the Course Portal subject application.

After sign-in, choose a course.

## Demo A — Standard course

Select a standard course.

Expected trace:

```text
request                       OK
standard-course-policy        OK — no Vault credential required
enrollment                    SUCCESS
```

## Demo B — Premium course

Select a premium course.

Expected execution trace:

```text
1. Request received
2. Premium course requires protected tool
3. Course Assistant obtains actor token
4. IBM Verify token exchange issues delegated JWT
5. Vault accepts delegated JWT and returns API key
6. Course Assistant calls Premium Enrollment Tool
7. Tool validates API key
8. Enrollment succeeds
```

Expected status:

```text
Premium enrollment completed
```

## What the application deliberately logs

The demo displays safe claims and high-level flow stages. It must not log:

- full access tokens,
- client secrets,
- Vault synchronization token,
- API key value.

## Runtime security story 

> The Course Assistant does not own the downstream tool credential. IBM Verify establishes the human and agent delegation context. Vault independently verifies that the actor is a registered agent and that the subject policy, agent ceiling, and RAR all permit this exact secret read. Only then is the tool API key released just in time.
