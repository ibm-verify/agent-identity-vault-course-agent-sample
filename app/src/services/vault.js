// Copyright IBM Corp. All Rights Reserved.
// #
// SPDX-License-Identifier: Apache-2.0

'use strict';
const axios = require('axios');

function deepGet(obj, path) {
  return String(path || '').split('.').filter(Boolean)
    .reduce((value, key) => value && Object.prototype.hasOwnProperty.call(value, key) ? value[key] : undefined, obj);
}

async function readPremiumApiKey(exchangedJwt) {
  const base = String(process.env.VAULT_ADDR || '').replace(/\/$/, '');
  const apiPath = String(process.env.VAULT_SECRET_API_PATH || '').replace(/^\//, '');
  const headers = { 'X-Vault-Token': exchangedJwt };
  if (process.env.VAULT_NAMESPACE) headers['X-Vault-Namespace'] = process.env.VAULT_NAMESPACE;

  const response = await axios.get(`${base}/v1/${apiPath}`, { headers, timeout: 15000 });
  const field = process.env.VAULT_SECRET_FIELD || 'api_key';
  const candidates = [`data.data.${field}`, `data.${field}`, field];
  let value;
  let sourcePath;
  for (const candidate of candidates) {
    const candidateValue = deepGet(response.data, candidate);
    if (typeof candidateValue === 'string' && candidateValue.length) {
      value = candidateValue;
      sourcePath = candidate;
      break;
    }
  }
  if (!value) throw new Error(`Vault response did not contain configured field '${field}'`);
  return { apiKey: value, sourcePath, vaultPath: apiPath };
}

module.exports = { readPremiumApiKey };
