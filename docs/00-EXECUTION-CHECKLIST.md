<!--
Copyright IBM Corp. All Rights Reserved.

SPDX-License-Identifier: Apache-2.0
-->

# Execution checklist

Follow [the complete setup guide](../SETUP-GUIDE.md) in order.

| Step | Required checkpoint |
|---|---|
| 3 | Tools installed; repository extracted; lab.env created |
| 4 | Licensed Vault healthy; admin authentication works |
| 5 | Discovery/JWKS valid; OAuth profile, ACL, ceiling and sync token ready |
| 6 | All clients and human created; agent ACTIVE and API association verified |
| 7 | Containers ready; SSF stream; local and real webhook synchronization pass |
| 7A | Stored dummy key matches expected value |
| 8 | ADTs, subject mappings, delegation and Actor Criteria saved |
| 9 | App environment generated; dependencies and local tests pass |
| 10 | Human/actor/task/credential checks and Vault JWT HTTP 200 |
| 11 | Standard and approved premium enrollment succeed; disallowed premium denied |
| 12 | Path/write/task-bypass/lifecycle tests and recovery recorded |

Use ACCEPTANCE-RESULTS.md to enter actual observations.
