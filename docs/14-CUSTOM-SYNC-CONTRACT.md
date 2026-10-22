<!--
Copyright IBM Corp. All Rights Reserved.

SPDX-License-Identifier: Apache-2.0
-->

# Permanent agent synchronization contract

The Verify registry UUID is the identity key. Require an ACTIVE agent and exactly one explicit `agent_id` runtime association; read the current record from Verify on every supported event. The association gates eligibility and does not become the Vault alias name.

Provision one stable `verify-agent-<AgentID>` entity with `course-tool-subject`, an alias with `name=AgentID`, `external_id=AgentID` and the exact Verify `issuer`, and a registration referencing that entity with `ceiling_policies=["course-tool-ceiling"]` and `optional_authorization_details=false`.

On suspension disable the entity before deleting its registration. On reactivation reuse the entity. Fail on service errors or unknown states. Do not automatically remap conflicting aliases. Missing purpose on an ACTIVE agent skips provisioning; suspend and confirm disable before removing an existing association.

Use a restricted synchronization token. Runtime reads use a Verify credential JWT in the same namespace, never this provisioning token. No human Vault entity is required in this agent-subject model.

See [complete execution guide](../SETUP-GUIDE.md) and the bundled Antenna handler for concrete API calls. Custom adapters must prove the same checkpoints and lifecycle outcomes.
