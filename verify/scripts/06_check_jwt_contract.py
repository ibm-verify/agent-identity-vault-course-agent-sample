#!/usr/bin/env python3
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0

"""Inspect local claim contracts. Signature validation remains with Verify and Vault."""
import base64,json,os,sys,time
from pathlib import Path
role=sys.argv[1]; token=Path(sys.argv[2]).read_text().strip()
p=token.split('.')
if len(p)!=3: raise SystemExit('FAIL: expected JWT access token')
c=json.loads(base64.urlsafe_b64decode(p[1]+'='*(-len(p[1])%4)))
agent=os.environ['VERIFY_AGENT_ID']; issuer=os.environ['VERIFY_ISSUER']
assert c.get('iss')==issuer,'Wrong issuer'
assert isinstance(c.get('exp'),(int,float)) and c['exp']>time.time(),'Expired token'
if role=='actor': assert c.get('sub')==agent and c.get('client_id')==os.environ['ACTOR_CLIENT_ID'],'Wrong actor identity'
if role=='subject': assert c.get('sub') and c['sub']!=agent,'Expected human subject'
if role=='task':
 assert c.get('sub')!=agent and c.get('act',{}).get('sub')==agent,'Wrong task participants'
 assert any(d.get('type')=='urn:ibm:demo:verify:course_credential_task' and d.get('action')=='premium_enroll' and d.get('courseId')=='PREM-801' for d in c.get('authorization_details',[])),'Missing task RAR'
if role=='credential':
 assert c.get('sub')==agent and c.get('act',{}).get('sub')==agent,'Wrong credential participants'
 assert c.get('authorization_details')==[{'type':'vault:path_access','path':'course-tools/data/premium-enrollment','capabilities':['read']}],'Wrong credential RAR'
print(json.dumps({k:c[k] for k in ['iss','sub','client_id','act','authorization_details','iat','exp'] if k in c},indent=2))
print('PASS: '+role+' claim contract; remaining seconds='+str(int(c['exp']-time.time())))
