# 15. Product Documentation References

These links are included so implementers can verify product behavior and adapt the recipe to their tenant/build.

## IBM Verify

- OIDC application configuration, including grant types, JWT token settings, audiences, Token Exchange settings, `Require actor token`, actor validation, and authorization-detail restrictions:  
  https://www.ibm.com/docs/en/security-verify?topic=sign-configuring-single-in-openid-connect-application

- Token exchange concepts / IBM Verify SaaS:  
  https://docs.verify.ibm.com/verify/docs/token-exchange

- OAuth 2.0 Token Exchange concepts, including `subject_token`, `actor_token`, and `may_act`:  
  https://docs.verify.ibm.com/verify/docs/oauth-20-token-exchange

- IBM Verify OAuth token endpoint:  
  https://docs.verify.ibm.com/verify/reference/post_oauth2-token

- Authorization Detail Type management/reference:  
  https://docs.verify.ibm.com/verify/reference/readauthdetailtypetemplates

## HashiCorp Vault

- Native AI Agent Support overview:  
  https://developer.hashicorp.com/vault/docs/concepts/native-ai-agent-support

- Rich Authorization Requests (`vault:path_access`):  
  https://developer.hashicorp.com/vault/docs/concepts/native-ai-agent-support/rich-authorization-requests

- Agent Registry API:  
  https://developer.hashicorp.com/vault/api-docs/secret/agent-registry

- Vault Identity Entity Alias API:  
  https://developer.hashicorp.com/vault/api-docs/secret/identity/entity-alias

- OAuth Resource Server API:  
  https://developer.hashicorp.com/vault/api-docs/system/config-oauth-resource-server

- Vault Enterprise license behavior / PKI-only mode:  
  https://developer.hashicorp.com/vault/docs/license

- Vault KV v2 API:  
  https://developer.hashicorp.com/vault/api-docs/secret/kv/kv-v2

## Supplied reference material

The uploaded document `request.pdf` was used as a practical configuration reference for:

- OIDC application UI locations,
- `may_act` mapping,
- `vault:path_access` schema,
- Vault OAuth Resource Server `config_id`/identity binding concepts,
- delegated JWT use with Vault.

This cookbook intentionally presents only the configuration required for the current use case and does not require the reader to understand previous demo history.
