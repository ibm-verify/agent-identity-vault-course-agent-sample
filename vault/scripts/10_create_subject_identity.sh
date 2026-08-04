#!/usr/bin/env bash

# Copyright IBM Corp. All Rights Reserved.
# #
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail
DIR=$(cd "$(dirname "$0")" && pwd); ROOT=$(cd "$DIR/.." && pwd)
source "$DIR/_common.sh"; need_admin_token
: "${SUBJECT_TOKEN_SUB:?export SUBJECT_TOKEN_SUB from decoded subject JWT}"
: "${VERIFY_ISSUER:?export VERIFY_ISSUER, e.g. https://tenant/oauth2}"
if [[ -f "$ROOT/.oauth-runtime.env" ]]; then source "$ROOT/.oauth-runtime.env"; fi
: "${VAULT_OAUTH_MOUNT_ACCESSOR:?run 02_get_oauth_profile_binding.sh first}"
NAME="course-demo-subject-${SUBJECT_TOKEN_SUB//[^A-Za-z0-9_.-]/-}"
# Find/create entity by name.
ENTITY_JSON=$(vault read -format=json "identity/entity/name/$NAME" 2>/dev/null || true)
ENTITY_ID=$(printf '%s' "$ENTITY_JSON" | jq -r '.data.id // empty' 2>/dev/null || true)
if [[ -z "$ENTITY_ID" ]]; then
  ENTITY_JSON=$(vault write -format=json identity/entity name="$NAME" policies="course-tool-subject")
  ENTITY_ID=$(printf '%s' "$ENTITY_JSON" | jq -r '.data.id')
else
  vault write "identity/entity/id/$ENTITY_ID" name="$NAME" policies="course-tool-subject" >/dev/null
fi
# OAuth JWT resolution requires issuer + external_id at alias creation time.
# Vault prohibits adding/changing issuer after creation, so fail clearly on an incomplete legacy alias.
ENTITY_NOW=$(vault read -format=json "identity/entity/id/$ENTITY_ID")
ALIAS_ID=$(printf '%s' "$ENTITY_NOW" | jq -r \
  --arg name "$SUBJECT_TOKEN_SUB" --arg accessor "$VAULT_OAUTH_MOUNT_ACCESSOR" \
  '.data.aliases[]? | select(.name == $name and .mount_accessor == $accessor) | .id' | head -n1)
if [[ -n "$ALIAS_ID" ]]; then
  ALIAS_JSON=$(vault read -format=json "identity/entity-alias/id/$ALIAS_ID")
  ALIAS_ISSUER=$(printf '%s' "$ALIAS_JSON" | jq -r '.data.issuer // empty')
  ALIAS_EXTERNAL_ID=$(printf '%s' "$ALIAS_JSON" | jq -r '.data.external_id // empty')
  if [[ "$ALIAS_ISSUER" != "$VERIFY_ISSUER" || "$ALIAS_EXTERNAL_ID" != "$SUBJECT_TOKEN_SUB" ]]; then
    echo "ERROR: Existing subject alias $ALIAS_ID has missing/incorrect immutable OAuth binding." >&2
    echo "Expected issuer=$VERIFY_ISSUER external_id=$SUBJECT_TOKEN_SUB" >&2
    echo "Back up, delete, and recreate the alias using docs/13A-VALIDATED-SETUP-TROUBLESHOOTING.md." >&2
    exit 1
  fi
else
  vault write identity/entity-alias \
    name="$SUBJECT_TOKEN_SUB" \
    canonical_id="$ENTITY_ID" \
    mount_accessor="$VAULT_OAUTH_MOUNT_ACCESSOR" \
    issuer="$VERIFY_ISSUER" \
    external_id="$SUBJECT_TOKEN_SUB" >/dev/null
fi
printf 'export VAULT_SUBJECT_ENTITY_ID=%q\n' "$ENTITY_ID"
echo "Created/updated subject entity $ENTITY_ID with course-tool-subject policy."
