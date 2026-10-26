#!/usr/bin/env python3
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0

"""Exercise curl helper against a local fake issuer, including exact token-file handling."""
import base64,http.server,json,os,subprocess,tempfile,threading,time,urllib.parse
from pathlib import Path
root=Path(__file__).resolve().parents[2]
agent='fixture-agent';human='fixture-human';calls=[]
def jwt(claims):
 payload={'iss':issuer,'exp':int(time.time())+300,**claims}
 return 'header.'+base64.urlsafe_b64encode(json.dumps(payload).encode()).rstrip(b'=').decode()+'.signature'
class Handler(http.server.BaseHTTPRequestHandler):
 def log_message(self,*args):pass
 def do_POST(self):
  global task
  form={k:v[0] for k,v in urllib.parse.parse_qs(self.rfile.read(int(self.headers['Content-Length'])).decode()).items()};calls.append(form)
  if form['grant_type']=='client_credentials':token=jwt({'sub':agent,'client_id':'actor-client'})
  elif form['client_id']=='task-client':
   assert form['subject_token']==subject and form['actor_token']==actor
   token=jwt({'sub':human,'act':{'sub':agent},'authorization_details':json.loads(form['authorization_details'])});task=token
  else:
   assert form['client_id']=='credential-client' and form['subject_token']==task and form['actor_token']==actor
   token=jwt({'sub':agent,'act':{'sub':agent},'authorization_details':json.loads(form['authorization_details'])})
  self.send_response(200);self.end_headers();self.wfile.write(json.dumps({'access_token':token}).encode())
server=http.server.HTTPServer(('127.0.0.1',0),Handler);issuer='http://127.0.0.1:'+str(server.server_port)
subject=jwt({'sub':human});actor=jwt({'sub':agent,'client_id':'actor-client'})
task=''
threading.Thread(target=server.serve_forever,daemon=True).start()
try:
 with tempfile.TemporaryDirectory() as tmp:
  p=Path(tmp)/'.runtime';p.mkdir();(p/'subject.token').write_text(subject)
  env=os.environ.copy();env.update(VERIFY_ISSUER=issuer,VERIFY_TOKEN_URL=issuer+'/token',VERIFY_AGENT_ID=agent,ACTOR_CLIENT_ID='actor-client',ACTOR_CLIENT_SECRET='actor-secret',TASK_CLIENT_ID='task-client',TASK_CLIENT_SECRET='task-secret',CREDENTIAL_CLIENT_ID='credential-client',CREDENTIAL_CLIENT_SECRET='credential-secret')
  subprocess.run(['bash',str(root/'verify/scripts/03_exchange_obo_token.sh')],cwd=tmp,env=env,check=True,stdout=subprocess.DEVNULL)
  assert len(calls)==3
  assert (p/'credential.token').exists()
  assert all(not (v.endswith('\n') or v.endswith('\r')) for form in calls for k,v in form.items() if k in ['subject_token','actor_token'])
 print('PASS: curl helper sends actor, task and credential requests in sequence with exact token contents')
finally:server.shutdown();server.server_close()
