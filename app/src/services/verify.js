// Copyright IBM Corp. All Rights Reserved.
// #
// SPDX-License-Identifier: Apache-2.0

'use strict';
const axios = require('axios');
const { safeClaims } = require('../utils/jwt');

const TOKEN_EXCHANGE_GRANT = 'urn:ietf:params:oauth:grant-type:token-exchange';
const ACCESS_TOKEN_TYPE = 'urn:ietf:params:oauth:token-type:access_token';

function addClientAuth(params, headers, clientId, clientSecret, method) {
  if (method === 'client_secret_basic') {
    headers.Authorization = `Basic ${Buffer.from(`${clientId}:${clientSecret}`).toString('base64')}`;
  } else {
    params.set('client_id', clientId);
    params.set('client_secret', clientSecret);
  }
}

async function getActorToken() {
  const params = new URLSearchParams();
  params.set('grant_type', 'client_credentials');
  if (process.env.ACTOR_SCOPE) params.set('scope', process.env.ACTOR_SCOPE);
  const headers = { 'Content-Type': 'application/x-www-form-urlencoded' };
  addClientAuth(params, headers, process.env.ACTOR_CLIENT_ID, process.env.ACTOR_CLIENT_SECRET,
    process.env.ACTOR_CLIENT_AUTH_METHOD || 'client_secret_post');

  const response = await axios.post(process.env.VERIFY_TOKEN_URL, params.toString(), { headers, timeout: 15000 });
  if (!response.data || !response.data.access_token) throw new Error('IBM Verify actor token response did not contain access_token');
  return response.data.access_token;
}

function buildVaultAuthorizationDetails() {
  return [{
    type: 'vault:path_access',
    path: process.env.VAULT_SECRET_API_PATH || 'course-tools/data/premium-enrollment',
    capabilities: ['read']
  }];
}

async function exchangeForOboToken(subjectToken, actorToken) {
  const authorizationDetails = buildVaultAuthorizationDetails();
  const params = new URLSearchParams();
  params.set('grant_type', TOKEN_EXCHANGE_GRANT);
  params.set('subject_token', subjectToken);
  params.set('subject_token_type', ACCESS_TOKEN_TYPE);
  params.set('actor_token', actorToken);
  params.set('actor_token_type', ACCESS_TOKEN_TYPE);
  params.set('requested_token_type', ACCESS_TOKEN_TYPE);
  params.set('authorization_details', JSON.stringify(authorizationDetails));
  if (process.env.TOKEN_EXCHANGE_REQUEST_AUDIENCE) params.set('audience', process.env.TOKEN_EXCHANGE_REQUEST_AUDIENCE);
  if (process.env.TOKEN_EXCHANGE_REQUESTED_SCOPE) params.set('scope', process.env.TOKEN_EXCHANGE_REQUESTED_SCOPE);

  const headers = { 'Content-Type': 'application/x-www-form-urlencoded' };
  addClientAuth(params, headers, process.env.TOKEN_EXCHANGE_CLIENT_ID, process.env.TOKEN_EXCHANGE_CLIENT_SECRET,
    process.env.TOKEN_EXCHANGE_CLIENT_AUTH_METHOD || 'client_secret_post');

  const response = await axios.post(process.env.VERIFY_TOKEN_URL, params.toString(), { headers, timeout: 15000 });
  if (!response.data || !response.data.access_token) throw new Error('IBM Verify token exchange response did not contain access_token');
  return {
    accessToken: response.data.access_token,
    authorizationDetails,
    actorClaims: safeClaims(actorToken),
    exchangedClaims: safeClaims(response.data.access_token)
  };
}

module.exports = { getActorToken, buildVaultAuthorizationDetails, exchangeForOboToken };
