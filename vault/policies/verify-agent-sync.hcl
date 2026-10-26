# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0

path "auth/token/lookup-self" { capabilities = ["read"] }
path "identity/entity" { capabilities = ["create", "update"] }
path "identity/entity/name/*" { capabilities = ["read"] }
path "identity/entity/id/*" { capabilities = ["read", "update"] }
path "identity/lookup/entity" { capabilities = ["update"] }
path "identity/entity-alias" { capabilities = ["create", "update"] }
path "identity/entity-alias/id/*" { capabilities = ["read"] }
path "agent-registry/register" { capabilities = ["create", "update"] }
path "agent-registry/registration/entity-id/*" { capabilities = ["read"] }
path "agent-registry/registration/id/*" { capabilities = ["read", "update", "delete"] }
