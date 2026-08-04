#!/usr/bin/env bash

# Copyright IBM Corp. All Rights Reserved.
# #
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail
for c in node npm curl jq vault python3; do
  command -v "$c" >/dev/null || { echo "Missing prerequisite: $c" >&2; exit 1; }
  printf 'OK: %-10s %s\n' "$c" "$(command -v "$c")"
done
node --version
npm --version
vault version
