<!--
Copyright IBM Corp. All Rights Reserved.

SPDX-License-Identifier: Apache-2.0
-->

# Security Notice

This repository is a demonstration/reference implementation.

- Never commit real client secrets, Vault tokens, OAuth access tokens, or downstream API keys.
- Use Vault root/admin credentials only for initial bootstrap.
- Synchronization must use a restricted provisioning token.
- Agent runtime must use the IBM Verify delegated JWT, not the synchronization token.
- Keep `optional_authorization_details=false` for this demo so RAR is required.
- Use short-lived access tokens.
- Replace demo API keys and local HTTP endpoints before any production deployment.
- Review Vault policies and sync-token policy for least privilege in your namespace.
- The native AI-agent support referenced here is documented by HashiCorp as an Enterprise beta capability; validate product support requirements before production use.
