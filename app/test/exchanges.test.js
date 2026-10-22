// Copyright IBM Corp. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

'use strict';
const assert=require('assert'),fs=require('fs'),vm=require('vm');
const agent='agent-123',issuer='https://verify.example/oauth2',exp=Math.floor(Date.now()/1000)+300;
const jwt=c=>['eyJhbGciOiJSUzI1NiJ9',Buffer.from(JSON.stringify({iss:issuer,exp,...c})).toString('base64url'),'signature'].join('.');
const actor=jwt({sub:agent,client_id:'runtime'}),human=jwt({sub:'human'});
const task=jwt({sub:'human',act:{sub:agent},authorization_details:[{type:'urn:ibm:demo:verify:course_credential_task',action:'premium_enroll',courseId:'PREM-801',reference:'ref'}]});
const details=[{type:'vault:path_access',path:'course-tools/data/premium-enrollment',capabilities:['read']}];
const credential=jwt({sub:agent,act:{sub:agent},authorization_details:details});
let calls=[],outputs=[task,credential];
const env={VERIFY_AGENT_ID:agent,VERIFY_ISSUER:issuer,VERIFY_TOKEN_URL:issuer+'/token',ACTOR_CLIENT_ID:'runtime',TASK_CLIENT_ID:'task-client',TASK_CLIENT_SECRET:'task-secret',CREDENTIAL_CLIENT_ID:'credential-client',CREDENTIAL_CLIENT_SECRET:'credential-secret'};
const box={module:{exports:{}},Buffer,URLSearchParams,process:{env},require(n){if(n==='axios')return {async post(url,body){calls.push(new URLSearchParams(body));return {data:{access_token:outputs.shift()}}}};if(n==='../utils/jwt')return {safeClaims:t=>JSON.parse(Buffer.from(t.split('.')[1],'base64url'))};throw Error(n)}};
vm.runInNewContext(fs.readFileSync(__dirname+'/../src/services/verify.js','utf8'),box);
const api=box.module.exports;
(async()=>{
 await api.exchangeForOboToken(human,actor,{courseId:'PREM-801',reference:'ref'});
 assert.equal(calls.length,2);assert.equal(calls[0].get('subject_token'),human);assert.equal(calls[1].get('subject_token'),task);
 assert.equal(calls[0].get('actor_token'),actor);assert.equal(calls[1].get('actor_token'),actor);
 assert.equal(calls[0].get('client_id'),'task-client');assert.equal(calls[1].get('client_id'),'credential-client');
 assert.equal(JSON.parse(calls[0].get('authorization_details'))[0].courseId,'PREM-801');
 assert.throws(()=>api.checkToken(jwt({sub:'client-id',client_id:'runtime'}),'actor'));
 assert.throws(()=>api.checkToken(jwt({sub:agent,act:{sub:'other'},authorization_details:details}),'credential'));
 assert.throws(()=>api.checkToken(jwt({sub:agent,act:{sub:agent},authorization_details:[{...details[0],path:'wrong'}]}),'credential'));
 assert.throws(()=>api.checkToken(jwt({sub:agent,act:{sub:agent},authorization_details:details,exp:1}),'credential'));
 calls=[];outputs=[jwt({sub:'other-human',act:{sub:agent}})];
 await assert.rejects(()=>api.exchangeForOboToken(human,actor,{courseId:'PREM-801',reference:'ref'}));assert.equal(calls.length,1);
 console.log('PASS: two-stage requests; reject wrong actor, subject, path and expired JWT; stop before credential stage on invalid task');
})().catch(e=>{console.error(e);process.exitCode=1});
