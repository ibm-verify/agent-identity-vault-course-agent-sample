// Copyright IBM Corp. All Rights Reserved.
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

function claims(token) {
  try { return JSON.parse(Buffer.from(token.split('.')[1], 'base64url').toString()); }
  catch (_) { throw new Error('Expected a JWT access token'); }
}
function checkToken(token, role, humanSub) {
  const c = claims(token), agent = process.env.VERIFY_AGENT_ID;
  if (!agent || !Number.isFinite(c.exp) || c.exp <= Date.now()/1000 || c.iss !== process.env.VERIFY_ISSUER)
    throw new Error(role + ': missing AgentID, wrong issuer or expired JWT');
  if (role === 'actor' && (c.sub !== agent || c.client_id !== process.env.ACTOR_CLIENT_ID))
    throw new Error('Actor JWT must identify the configured permanent AgentID and runtime client');
  if (role === 'task' && (c.sub !== humanSub || c.act?.sub !== agent))
    throw new Error('Task JWT must retain the human subject and permanent agent actor');
  if (role === 'credential') {
    if (c.sub !== agent || c.act?.sub !== agent) throw new Error('Credential JWT sub and immediate act.sub must equal AgentID');
    const expected = buildVaultAuthorizationDetails()[0];
    const granted = c.authorization_details;
    if (!Array.isArray(granted) || granted.length !== 1 || granted[0].type !== expected.type ||
        granted[0].path !== expected.path || JSON.stringify(granted[0].capabilities) !== '["read"]')
      throw new Error('Credential JWT must grant exactly the configured Vault read');
  }
  return c; // Diagnostic contract checks; Verify and Vault perform cryptographic validation.
}
async function exchange(subjectToken, actorToken, prefix, details) {
  const params = new URLSearchParams({grant_type:TOKEN_EXCHANGE_GRANT,
    subject_token:subjectToken, subject_token_type:ACCESS_TOKEN_TYPE,
    actor_token:actorToken, actor_token_type:ACCESS_TOKEN_TYPE,
    requested_token_type:ACCESS_TOKEN_TYPE, authorization_details:JSON.stringify(details)});
  if (process.env[prefix+'_AUDIENCE']) params.set('audience',process.env[prefix+'_AUDIENCE']);
  if (process.env[prefix+'_SCOPE']) params.set('scope',process.env[prefix+'_SCOPE']);
  const headers = {'Content-Type':'application/x-www-form-urlencoded'};
  addClientAuth(params,headers,process.env[prefix+'_CLIENT_ID'],process.env[prefix+'_CLIENT_SECRET'],
    process.env[prefix+'_CLIENT_AUTH_METHOD'] || 'client_secret_post');
  const response = await axios.post(process.env.VERIFY_TOKEN_URL,params.toString(),{headers,timeout:15000});
  if (!response.data?.access_token) throw new Error(prefix+' response missing access_token');
  return response.data.access_token;
}
async function exchangeForOboToken(subjectToken, actorToken, task) {
  checkToken(actorToken,'actor');
  const human = claims(subjectToken).sub;
  const taskDetails = [{type:'urn:ibm:demo:verify:course_credential_task',
    action:'premium_enroll',courseId:task.courseId,reference:task.reference}];
  const taskToken = await exchange(subjectToken,actorToken,'TASK',taskDetails);
  const taskClaims = checkToken(taskToken,'task',human);
  if (!Array.isArray(taskClaims.authorization_details) || !taskClaims.authorization_details.some(d =>
      d.type === taskDetails[0].type && d.action === 'premium_enroll' &&
      d.courseId === task.courseId && d.reference === task.reference))
    throw new Error('Task JWT is missing the granted enrollment task');
  const authorizationDetails = buildVaultAuthorizationDetails();
  const credentialToken = await exchange(taskToken,actorToken,'CREDENTIAL',authorizationDetails);
  checkToken(credentialToken,'credential');
  return {accessToken:credentialToken,authorizationDetails,taskClaims:safeClaims(taskToken),
    actorClaims:safeClaims(actorToken),exchangedClaims:safeClaims(credentialToken)};
}
module.exports = {getActorToken,buildVaultAuthorizationDetails,exchangeForOboToken,checkToken};
