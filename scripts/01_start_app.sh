#!/usr/bin/env bash

# Copyright IBM Corp. All Rights Reserved.
# #
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail
cd "$(dirname "$0")/../app"
[[ -f .env ]] || { echo 'app/.env missing. Copy app/.env.example and fill tenant values.' >&2; exit 1; }
npm ci
npm test
npm start
