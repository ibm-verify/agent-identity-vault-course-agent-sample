# Runnable Course Portal Demo

This folder contains the sample application used after IBM Verify and Vault have passed the smoke test.

## What it demonstrates

- Human sign-in with Authorization Code + PKCE.
- Course Assistant actor token by Client Credentials.
- RFC 8693 token exchange through the `Course Vault Token Exchange` OIDC application.
- Delegated JWT presented directly to Vault.
- Premium tool API key read from Vault and supplied to the protected tool.
- Standard course path that does not require the protected credential.

## Run

Follow the main cookbook first. Then:

```bash
cp .env.example .env
# edit .env
npm ci
npm test
npm start
```

Open `http://localhost:4000`.

Do not place Vault root/admin or synchronization tokens in `.env`.
