// Copyright IBM Corp. All Rights Reserved.
// #
// SPDX-License-Identifier: Apache-2.0

'use strict';

function decodeSegment(segment) {
  const normalized = segment.replace(/-/g, '+').replace(/_/g, '/');
  const padded = normalized.padEnd(Math.ceil(normalized.length / 4) * 4, '=');
  return JSON.parse(Buffer.from(padded, 'base64').toString('utf8'));
}

function decodeJwtUnsafe(token) {
  try {
    const parts = String(token || '').split('.');
    if (parts.length !== 3) return {};
    return decodeSegment(parts[1]);
  } catch (_) {
    return {};
  }
}

function safeClaims(token) {
  const payload = decodeJwtUnsafe(token);
  const result = {};
  for (const key of ['iss', 'sub', 'aud', 'azp', 'client_id', 'scope', 'act', 'authorization_details', 'iat', 'exp']) {
    if (payload[key] !== undefined) result[key] = payload[key];
  }
  return result;
}

module.exports = { decodeJwtUnsafe, safeClaims };
