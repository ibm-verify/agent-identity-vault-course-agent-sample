<!--
Copyright IBM Corp. All Rights Reserved.

SPDX-License-Identifier: Apache-2.0
-->

# 11. Run the Course Portal demonstration

**Purpose:** exercise the complete application after the individual remote boundaries have passed.

## 11.1 Start the portal — Terminal D

Open a terminal, navigate to the extracted `agent-identity-vault-course-agent-sample-main` directory and run:

```bash
cd app
npm start
```

**Expected:** `Course demo listening at http://localhost:4000`. The Step 10 sign-in helper must already have exited. Keep Terminal D running. The server loads the `app/.env` generated in Step 9.

## 11.2 Sign in and validate the standard path

1. Open `http://localhost:4000` in the browser.
2. Choose sign in and authenticate as Course Learner.
3. Enroll in **BAS-101 — Security Fundamentals**.

**Expected:** enrollment succeeds and appears in My enrollments. The trace indicates no Vault credential was required for this standard course.

## 11.3 Validate premium enrollment

Choose **PREM-801 — Enterprise AI Agent Security** and enroll.

**Expected:** the trace shows actor authentication, task token exchange, credential token exchange, Vault credential read and protected Course API HTTP 200. The course appears in My enrollments. Credential values are redacted.

The app obtains fresh actor/task/credential tokens for each premium request. The human access token comes from the current sign-in session. If it expires, sign out and sign in again.

## 11.4 Confirm the policy boundary

Choose **PREM-901 — Advanced Agent Governance** and enroll.

**Expected:** the operation is denied before the protected API completes because this lab's allowed task schema/criteria is restricted to PREM-801. No PREM-901 enrollment should appear. This is an intentional authorization test, not a storage failure.

The downstream API is a demonstration API-key consumer. It does not validate the task JWT or process an actual payment. Enrollments are stored in the browser's server-side session and reset when that session/app state is cleared.

**Stop checkpoint:** BAS-101 and PREM-801 succeed, PREM-901 is denied. Continue to Step 12 for lifecycle and negative tests.
