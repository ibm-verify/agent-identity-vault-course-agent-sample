<!--
Copyright IBM Corp. All Rights Reserved.

SPDX-License-Identifier: Apache-2.0
-->

# Lab acceptance record

Record observed outcomes after following the setup guide. Do not mark a row passed from its expected result alone.

Tenant: ____________________  Vault build: ____________________  Date: ____________________

| Check | Expected | Observed result / evidence | Status |
|---|---|---|---|
| Vault health / admin | Healthy, unsealed / authenticated | | Not run |
| OAuth trust and policies | Enabled issuer profile and exact-path permissions | | Not run |
| Verify Agent GET | ACTIVE, one explicit agent_id association | | Not run |
| Local synthetic synchronization | Entity, issuer-bound alias, ACL and registration | | Not run |
| Actual tenant webhook delivery | Real event updates same entity | | Not run |
| Human / actor authentication | Human subject / permanent AgentID | | Not run |
| Task exchange | Human subject, agent actor, granted PREM-801 task | | Not run |
| Credential exchange | Agent subject and actor, exact read RAR | | Not run |
| Direct Vault JWT read | HTTP 200, expected dummy key | | Not run |
| Portal BAS-101 / PREM-801 | Success / success | | Not run |
| Portal PREM-901 | Denied | | Not run |
| Other path / write | Denied with current token | | Not run |
| Task bypass | Issuance denied for missing task boundary | | Not run |
| Suspension | Disabled entity, removed registration, current-token read denied | | Not run |
| Reactivation | Same entity, restored registration, fresh read succeeds | | Not run |
| Wrong backend key / restoration | API 403 / API success | | Not run |
| Second human | Different human task subject; same final AgentID/entity | | Not run |
