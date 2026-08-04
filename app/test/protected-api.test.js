// Copyright IBM Corp. All Rights Reserved.
// #
// SPDX-License-Identifier: Apache-2.0

'use strict';
process.env.PREMIUM_API_EXPECTED_KEY = 'course-premium-demo-key-2026';
const assert = require('assert');
const { app } = require('../src/server');

async function run() {
  const server = app.listen(0, '127.0.0.1');
  await new Promise(resolve => server.once('listening', resolve));
  const { port } = server.address();
  const url = `http://127.0.0.1:${port}/api/premium/enroll`;
  try {
    const ok = await fetch(url, {
      method: 'POST',
      headers: {'Content-Type':'application/json','X-Course-API-Key':'course-premium-demo-key-2026'},
      body: JSON.stringify({courseId:'PREM-801',subject:'demo'})
    });
    assert.strictEqual(ok.status, 200);
    const denied = await fetch(url, {
      method: 'POST',
      headers: {'Content-Type':'application/json','X-Course-API-Key':'intentionally-wrong-premium-key'},
      body: JSON.stringify({courseId:'PREM-801',subject:'demo'})
    });
    assert.strictEqual(denied.status, 403);
    const body = await denied.json();
    assert.strictEqual(body.error, 'invalid_premium_course_api_key');
    console.log('Protected API success/negative tests passed.');
  } finally {
    await new Promise(resolve => server.close(resolve));
  }
}
run().catch(error => { console.error(error); process.exit(1); });
