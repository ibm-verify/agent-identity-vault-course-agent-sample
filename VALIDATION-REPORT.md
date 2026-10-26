<!--
Copyright IBM Corp. All Rights Reserved.

SPDX-License-Identifier: Apache-2.0
-->

# Validation scope

Local checks cover handler event parsing, provisioning behavior, duplicate delivery, lifecycle transitions, purpose eligibility and API-error handling. Mocked exchange tests cover the two-stage requests and rejection of invalid identity/path/expiry contracts. Syntax, JSON and documentation links are also checked.

These checks do not establish live product compatibility. A complete lab run must validate tenant authentication, client entitlements, saved mappings/criteria, webhook delivery, SSF authentication, the licensed Vault build and its equal-subject/actor behavior, the credential read, and lifecycle denials.

Follow SETUP-GUIDE.md and record actual outcomes in docs/ACCEPTANCE-RESULTS.md. Every live checkpoint must pass on the environment being evaluated. A product error must be resolved rather than bypassed by weakening the policy.

## Package check status

| Check | Status |
|---|---|
| Synchronization handler tests | Passed, 22 checks |
| Mocked application exchange tests | Passed |
| Curl exchange helper against local fake issuer | Passed |
| Generated portal environment and Antenna templates | Passed with fixture settings; one root lab.env supplies handlers and stream authentication |
| Bootstrap HTTP payloads and restricted policy | Passed against local mock server |
| Source syntax, JSON, internal documentation links and Bash command blocks | Passed |
| Dependency-based portal/API tests | Pending; dependency retrieval returned registry HTTP 503 |
| Live Verify, Antenna and Vault acceptance checks | Run using the setup guide and record actual results |
