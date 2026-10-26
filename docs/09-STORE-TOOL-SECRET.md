<!--
Copyright IBM Corp. All Rights Reserved.

SPDX-License-Identifier: Apache-2.0
-->

# 9. Prepare application configuration and test dependencies

**Purpose:** build the portal environment from the settings already collected and validate the local application before interactive use.

```bash
cd "$UC3_ROOT"
source lab.env
python3 scripts/03_write_app_env.py
cd app
npm ci
npm run check
npm test
cd "$UC3_ROOT"
node sync/antenna/reference-implementation/tests/test_handlers.cjs
python3 verify/tests/test_exchange_helper.py
```

**Expected:** the configuration helper prints `PASS`, dependency installation completes, JavaScript syntax checks pass, portal/API/exchange tests pass, and all synchronization checks pass. The portal file contains runtime client credentials only; it excludes the Vault administrator token, synchronization token and Verify setup client credentials.

If npm cannot reach the package registry, correct the workstation's network/proxy/registry settings and retry `npm ci`. Do not assume dependencies were installed after a failed command. If any test fails, resolve it before proceeding.

No server is started in this step. Port 4000 is used temporarily by the sign-in helper in Step 10 and then by the portal in Step 11.

**Stop checkpoint:** `app/.env` exists, dependency installation and local tests pass. Continue to Step 10.
