<!--
Copyright IBM Corp. All Rights Reserved.

SPDX-License-Identifier: Apache-2.0
-->

# Use case and outcomes

A human requests course enrollment. Standard courses use a local path. For PREM-801, the Course Assistant receives a human-context task token, exchanges it for an agent-scoped credential-read token, retrieves a dummy API key from Vault and calls the protected course API.

IBM Agent Identity provides the permanent agent identity and delegation controls. Antenna synchronizes lifecycle state. Vault resolves the issuer-bound AgentID alias and intersects subject ACL, actor ceiling and RAR permissions before releasing the credential.

Follow [the setup guide](../SETUP-GUIDE.md) and record [actual acceptance results](ACCEPTANCE-RESULTS.md).
