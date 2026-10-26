#!/usr/bin/env python3
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0

"""Sign in the lab human with PKCE, save an access token privately, never display it."""
import base64, hashlib, http.server, json, os, secrets, time, urllib.parse, urllib.request, webbrowser
from pathlib import Path
issuer=os.environ['VERIFY_ISSUER']; client=os.environ['WEB_CLIENT_ID']; secret=os.environ['WEB_CLIENT_SECRET']
redirect='http://localhost:4000/callback'
with urllib.request.urlopen(issuer+'/.well-known/openid-configuration',timeout=20) as resp: metadata=json.load(resp)
assert metadata['issuer']==issuer,'Discovery issuer mismatch'
verifier=secrets.token_urlsafe(48);state=secrets.token_urlsafe(32)
challenge=base64.urlsafe_b64encode(hashlib.sha256(verifier.encode()).digest()).rstrip(b'=').decode()
result={}
class Handler(http.server.BaseHTTPRequestHandler):
 def log_message(self,*args): pass
 def do_GET(self):
  u=urllib.parse.urlparse(self.path)
  if u.path!='/callback':self.send_error(404);return
  q=urllib.parse.parse_qs(u.query)
  if q.get('state')!=[state]:self.send_error(400,'State mismatch');return
  if 'error' in q:result['error']=q['error'][0]
  elif 'code' in q:result['code']=q['code'][0]
  else:self.send_error(400,'Missing code');return
  self.send_response(200);self.end_headers();self.wfile.write(b'Sign-in received. Return to the terminal.')
server=http.server.HTTPServer(('127.0.0.1',4000),Handler);server.timeout=1
params={'client_id':client,'response_type':'code','redirect_uri':redirect,'scope':'openid profile email','state':state,'code_challenge':challenge,'code_challenge_method':'S256'}
url=metadata['authorization_endpoint']+'?'+urllib.parse.urlencode(params)
print('Sign in using the browser. If it does not open, use this URL:\n'+url,flush=True);webbrowser.open(url)
deadline=time.time()+300
try:
 while not result and time.time()<deadline:server.handle_request()
finally:server.server_close()
if not result.get('code'):raise SystemExit('Sign-in failed or timed out: '+result.get('error','no callback'))
body=urllib.parse.urlencode({'grant_type':'authorization_code','client_id':client,'client_secret':secret,'code':result['code'],'redirect_uri':redirect,'code_verifier':verifier}).encode()
request=urllib.request.Request(metadata['token_endpoint'],data=body,headers={'Content-Type':'application/x-www-form-urlencoded'})
try:
 with urllib.request.urlopen(request,timeout=20) as resp:token=json.load(resp)['access_token']
except urllib.error.HTTPError as e:raise SystemExit('Code exchange failed HTTP '+str(e.code)+'. Check confidential-client post authentication and repeat sign-in.')
p=Path('.runtime');p.mkdir(exist_ok=True);p.chmod(0o700)
f=p/'subject.token';f.write_text(token);f.chmod(0o600)
print('PASS: .runtime/subject.token saved. The callback listener is now stopped.')
