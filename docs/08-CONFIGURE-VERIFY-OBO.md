<!--
Copyright IBM Corp. All Rights Reserved.

SPDX-License-Identifier: Apache-2.0
-->

# 8. Configure authorization details and delegation rules

**Purpose:** authorize the human-context task and then convert its authority to a narrow agent-subject credential-read JWT. The second exchange uses the task token as `subject_token`, not the original human token. The final `act` is retained.

## 8.1 Register the two authorization detail types

Refresh the setup API token if it has expired by repeating Step 6.1. Then:

```bash
cd "$UC3_ROOT"
bash verify/scripts/05_create_vault_path_access_adt.sh
```

**Expected:** `PASS` for both `vault:path_access` and `urn:ibm:demo:verify:course_credential_task`. The helper builds the create payload from the bundled schema, sends it to `/v1.0/auth-detail-types`, and stores responses privately under `.runtime/`.

A 409 means that type already exists in the tenant. The helper still attempts both types, then stops at a compatibility checkpoint. Inspect each existing schema in the console and confirm it accepts the request below; once confirmed, proceed to the application bindings without recreating the type. Do not overwrite a shared type or rename `vault:path_access` as a workaround. A 401/403 means the setup API token or entitlement needs correction.

In each exchange application's **Sign-on → Authorization details** settings, attach only its type and reject unknown types:

| Application | Allowed type | Requested fields |
|---|---|---|
| Course Task Exchange | `urn:ibm:demo:verify:course_credential_task` | `action=premium_enroll`, `courseId=PREM-801`, unique `reference` |
| Course Credential Exchange | `vault:path_access` | `path=course-tools/data/premium-enrollment`, `capabilities=["read"]` |

If the tenant requires consent/preapproval for either type, complete the user grant through its supported approval workflow. Keep consent controls enabled; an issuance error is not a reason to bypass them.

## 8.2 Bind Runtime and Credential Exchange to the permanent AgentID

For **Course Assistant Runtime**, open **Sign-on → Endpoint configuration → ID token and user info → Edit**. Add a custom rule targeting `sub`. Its value is a quoted string containing the real registry UUID, for example `"<your-actual-AgentID>"`. Save.

Apply the same `sub` rule to **Course Credential Exchange**. Leave Course Portal and Course Task Exchange subjects unchanged. Do not add a rule clearing `act`.

These are administrator-reviewed bindings for this dedicated agent. Never let the caller select the trusted output AgentID. New tokens must be issued after changing mappings.

**Expected contract:** actor token subject = AgentID; task token subject = human; credential token subject and immediate `act.sub` = AgentID. Step 10 checks the actual signed output.

## 8.3 Permit the actor in each incoming subject context

Open **Course Portal → Sign-on → Endpoint configuration → Introspect → Edit**. Add a custom rule targeting `may_act` with this object, replacing both placeholders:

```json
{"sub":"<actual-AgentID>","client_id":"<Course-Assistant-Runtime-client-id>"}
```

Add the same `may_act` rule to **Course Task Exchange**. The first mapping permits the runtime actor against the human's token; the second permits it when the task token becomes the next subject token. Keep default actor validation enabled on both exchange applications.

**Expected:** both rules are saved on the correct applications. `may_act` is subject-token introspection context; it is not an extra form parameter in the exchange request.

## 8.4 Restrict the actual input clients and task

Generate the criteria with your exported IDs:

```bash
python3 - <<'PYRULE'
import os
from pathlib import Path
actor=os.environ['ACTOR_CLIENT_ID']; agent=os.environ['VERIFY_AGENT_ID']
portal=os.environ['WEB_CLIENT_ID']; task=os.environ['TASK_CLIENT_ID']
base=f"requestContext.actor_token.client_id == '{actor}' &&\nrequestContext.actor_token.sub == '{agent}' &&\n"
Path('.runtime/task-actor-criteria.cel').write_text(base+f"requestContext.subject_token.client_id == '{portal}'\n")
Path('.runtime/credential-actor-criteria.cel').write_text(base+f"requestContext.subject_token.client_id == '{task}' &&\n"+
 "has(requestContext.subject_token.authorization_details) &&\n"+
 "requestContext.subject_token.authorization_details.exists(d,\n"+
 " d.type == 'urn:ibm:demo:verify:course_credential_task' &&\n"+
 " d.action == 'premium_enroll' && d.courseId == 'PREM-801')\n")
print('PASS: generated both criteria files')
PYRULE
cat .runtime/task-actor-criteria.cel
cat .runtime/credential-actor-criteria.cel
```

Open **Course Task Exchange → Sign-on → Token exchange → Actor criteria → Set criteria** and paste the first file. Apply the second file to **Course Credential Exchange**. Save each rule and test it with the console's incoming-token context where available. Do not remove task validation to make an exchange succeed.

The rules restrict this demonstration to PREM-801 and the dedicated client/actor chain. PREM-901 is a deliberate disallowed premium course. Business eligibility, real purchase authorization and payment approval require trusted business rules in a production task service/API; this sample does not implement those services or CIBA.

**Stop checkpoint:** two types registered and bound, correct subject mappings saved, both `may_act` rules and restrictive Actor Criteria saved. Continue to Step 9.
