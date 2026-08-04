#!/usr/bin/env bash

# Copyright IBM Corp. All Rights Reserved.
# #
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail
DIR=$(cd "$(dirname "$0")" && pwd); source "$DIR/_common.sh"; need_admin_token
if vault secrets list -format=json | jq -e 'has("course-tools/")' >/dev/null; then
  echo 'course-tools/ already enabled.'
else
  vault secrets enable -path=course-tools kv-v2
fi
