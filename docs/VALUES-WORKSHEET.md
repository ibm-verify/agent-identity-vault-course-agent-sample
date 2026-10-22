<!--
Copyright IBM Corp. All Rights Reserved.

SPDX-License-Identifier: Apache-2.0
-->

# Values worksheet

Use `app/.env.example`, `verify/scripts/00_env.example.sh` and the Antenna local environment template.

| Check | Expected |
|---|---|
| Actor sub | Permanent VERIFY_AGENT_ID |
| Task sub | Human subject |
| Task immediate act.sub | VERIFY_AGENT_ID |
| Credential sub and immediate act.sub | VERIFY_AGENT_ID |
| Alias name/external_id | VERIFY_AGENT_ID |
| Alias issuer | Exact credential JWT iss |
| Entity policy | course-tool-subject |
| Registration ceiling | course-tool-ceiling |
| RAR/ACL/ceiling/secret path | course-tools/data/premium-enrollment |

Get jwks_uri from actual issuer discovery; keep real secrets out of this worksheet and Git.
