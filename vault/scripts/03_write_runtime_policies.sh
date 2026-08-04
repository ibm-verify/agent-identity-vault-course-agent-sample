#!/usr/bin/env bash

# Copyright IBM Corp. All Rights Reserved.
# #
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail
DIR=$(cd "$(dirname "$0")" && pwd); ROOT=$(cd "$DIR/.." && pwd)
source "$DIR/_common.sh"; need_admin_token
vault policy write course-tool-subject "$ROOT/policies/course-tool-subject.hcl"
vault policy write course-tool-ceiling "$ROOT/policies/course-tool-ceiling.hcl"
vault policy read course-tool-subject
vault policy read course-tool-ceiling
