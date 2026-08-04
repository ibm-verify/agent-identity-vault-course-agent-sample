# Validation Report

Validated locally before packaging:

- JSON syntax for Postman, environment, course catalog, ADT, and Vault profile templates: **PASS**
- Bash syntax for repository scripts, including Antenna reference scripts: **PASS**
- Node.js static syntax checks: **PASS**
- Course demo static-flow tests: **PASS**
- Protected Premium Tool success test with matching API key: **PASS**
- Protected Premium Tool HTTP 403 test with wrong API key: **PASS**
- Markdown relative file/image links: **PASS**
- Legacy/historical configuration wording removed from the customer execution path: **PASS**

## External validation still required in your environment

The following cannot be executed without your IBM Verify tenant and Vault Enterprise environment:

- IBM Verify Agent creation and OAuth-client association.
- Agent lifecycle delivery and Antenna/custom synchronization.
- Vault Enterprise OAuth Resource Server and Agent Registry feature checks.
- IBM Verify Authorization Code + PKCE subject login.
- IBM Verify actor token and RFC 8693 token exchange.
- Vault validation of the real delegated JWT, actor alias, Agent Registry registration, audience, policies, and RAR.

The cookbook uses hard STOP CHECKPOINTS so each external layer is proven before the next layer is introduced.
