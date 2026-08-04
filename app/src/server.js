// Copyright IBM Corp. All Rights Reserved.
// #
// SPDX-License-Identifier: Apache-2.0

'use strict';
require('dotenv').config({ path: require('path').resolve(__dirname, '../.env') });
const express = require('express');
const session = require('express-session');
const axios = require('axios');
const path = require('path');
const crypto = require('crypto');
const { Issuer, generators, custom } = require('openid-client');
const { listCourses, findCourse } = require('./services/catalog');
const { getActorToken, exchangeForOboToken } = require('./services/verify');
const { readPremiumApiKey } = require('./services/vault');
const { safeClaims } = require('./utils/jwt');

custom.setHttpOptionsDefaults({ timeout: 15000 });
const app = express();
let oidcClient;

app.set('view engine', 'ejs');
app.set('views', path.resolve(__dirname, '../views'));
app.use(express.urlencoded({ extended: true }));
app.use(express.json());
app.use(express.static(path.resolve(__dirname, '../public')));
app.use(session({
  name: 'course-vault-e2e-session',
  secret: process.env.SESSION_SECRET || 'replace-me-for-real-use',
  resave: false,
  saveUninitialized: false,
  cookie: { httpOnly: true, sameSite: 'lax', secure: false }
}));

function trace(step, status, detail = {}) {
  return { time: new Date().toISOString(), step, status, detail };
}

function requireLogin(req, res, next) {
  if (!req.session.user || !req.session.subjectAccessToken) return res.redirect('/');
  next();
}

function userKey(user) {
  return user.email || user.preferred_username || user.sub;
}

function enrollSession(req, course) {
  const current = Array.isArray(req.session.enrollments) ? req.session.enrollments : [];
  if (!current.some(item => item.courseId === course.id)) {
    current.push({ courseId: course.id, title: course.title, premium: course.premium, enrolledAt: new Date().toISOString() });
  }
  req.session.enrollments = current;
}

async function initOidc() {
  const issuer = await Issuer.discover(process.env.VERIFY_ISSUER);
  oidcClient = new issuer.Client({
    client_id: process.env.WEB_CLIENT_ID,
    client_secret: process.env.WEB_CLIENT_SECRET,
    redirect_uris: [process.env.REDIRECT_URI],
    response_types: ['code']
  });
}

app.get('/health', (_req, res) => res.json({ status: 'UP', service: 'course-premium-e2e' }));

app.get('/', (req, res) => {
  res.render('index', { user: req.session.user || null });
});

app.get('/login', (req, res) => {
  const codeVerifier = generators.codeVerifier();
  const state = generators.state();
  req.session.codeVerifier = codeVerifier;
  req.session.state = state;
  res.redirect(oidcClient.authorizationUrl({
    scope: process.env.WEB_SCOPE || 'openid profile email',
    code_challenge: generators.codeChallenge(codeVerifier),
    code_challenge_method: 'S256',
    state
  }));
});

app.get('/callback', async (req, res, next) => {
  try {
    const params = oidcClient.callbackParams(req);
    const tokenSet = await oidcClient.callback(process.env.REDIRECT_URI, params, {
      code_verifier: req.session.codeVerifier,
      state: req.session.state
    });
    const claims = tokenSet.claims();
    req.session.user = claims;
    req.session.subjectAccessToken = tokenSet.access_token;
    req.session.enrollments = [];
    if (String(process.env.SHOW_SAFE_TOKEN_CLAIMS || '').toLowerCase() === 'true') {
      console.log('[course-demo] subject access-token safe claims:', JSON.stringify(safeClaims(tokenSet.access_token), null, 2));
    }
    res.redirect('/courses');
  } catch (error) {
    next(error);
  }
});

app.get('/logout', (req, res) => req.session.destroy(() => res.redirect('/')));

app.get('/courses', requireLogin, (req, res) => {
  const result = req.session.lastResult || null;
  delete req.session.lastResult;
  res.render('courses', {
    user: req.session.user,
    courses: listCourses(),
    enrollments: req.session.enrollments || [],
    result
  });
});

app.post('/enroll', requireLogin, async (req, res) => {
  const course = findCourse(req.body.courseId);
  if (!course) {
    req.session.lastResult = { ok: false, message: 'Unknown course.', trace: [] };
    return res.redirect('/courses');
  }

  const flow = [];
  const correlationId = crypto.randomUUID(); // ordinary log correlation only; not a transaction token
  flow.push(trace('request', 'OK', { correlationId, courseId: course.id, premium: course.premium, user: userKey(req.session.user) }));

  try {
    if (!course.premium) {
      enrollSession(req, course);
      flow.push(trace('standard-course-policy', 'OK', { decision: 'No Vault credential required' }));
      req.session.lastResult = { ok: true, message: `Enrolled in ${course.title}.`, course, flowType: 'STANDARD', trace: flow };
      return res.redirect('/courses');
    }

    flow.push(trace('premium-course-policy', 'OK', { decision: 'Require IBM Verify OBO plus Vault secret' }));

    const actorToken = await getActorToken();
    flow.push(trace('actor-token', 'OK', { claims: safeClaims(actorToken) }));

    const exchange = await exchangeForOboToken(req.session.subjectAccessToken, actorToken);
    flow.push(trace('rfc8693-token-exchange', 'OK', {
      authorization_details: exchange.authorizationDetails,
      claims: exchange.exchangedClaims
    }));

    const vaultSecret = await readPremiumApiKey(exchange.accessToken);
    flow.push(trace('vault-oauth-jwt-read', 'OK', {
      path: vaultSecret.vaultPath,
      field: vaultSecret.sourcePath,
      credentialValue: '<redacted>'
    }));

    const apiResponse = await axios.post(process.env.PREMIUM_API_URL || `http://127.0.0.1:${process.env.PORT || 4000}/api/premium/enroll`, {
      courseId: course.id,
      subject: userKey(req.session.user),
      correlationId
    }, {
      headers: { 'X-Course-API-Key': vaultSecret.apiKey, 'Content-Type': 'application/json' },
      timeout: 15000,
      validateStatus: () => true
    });

    flow.push(trace('protected-premium-course-api', apiResponse.status === 200 ? 'OK' : 'DENY', {
      status: apiResponse.status,
      response: apiResponse.data
    }));

    if (apiResponse.status !== 200) {
      req.session.lastResult = {
        ok: false,
        message: apiResponse.data && apiResponse.data.message ? apiResponse.data.message : 'Premium enrollment was denied.',
        course,
        flowType: 'PREMIUM',
        trace: flow
      };
      return res.redirect('/courses');
    }

    enrollSession(req, course);
    req.session.lastResult = { ok: true, message: `Premium enrollment completed for ${course.title}.`, course, flowType: 'PREMIUM', trace: flow };
    return res.redirect('/courses');
  } catch (error) {
    const response = error.response;
    flow.push(trace('flow-error', 'ERROR', {
      componentStatus: response ? response.status : undefined,
      message: response && response.data ? response.data : error.message
    }));
    req.session.lastResult = {
      ok: false,
      message: 'Premium enrollment failed before the protected Course API completed. Review the safe execution trace and server logs.',
      course,
      flowType: 'PREMIUM',
      trace: flow
    };
    return res.redirect('/courses');
  }
});

// Downstream resource API. It independently trusts one configured API key.
app.post('/api/premium/enroll', (req, res) => {
  const supplied = req.get('X-Course-API-Key') || '';
  const expected = process.env.PREMIUM_API_EXPECTED_KEY || 'course-premium-demo-key-2026';
  const suppliedBuffer = Buffer.from(supplied);
  const expectedBuffer = Buffer.from(expected);
  const valid = suppliedBuffer.length === expectedBuffer.length && crypto.timingSafeEqual(suppliedBuffer, expectedBuffer);
  if (!valid) {
    return res.status(403).json({
      status: 'DENIED',
      error: 'invalid_premium_course_api_key',
      message: 'Premium course enrollment credential is invalid.',
      courseId: req.body.courseId
    });
  }
  return res.json({
    status: 'ENROLLED',
    courseId: req.body.courseId,
    subject: req.body.subject,
    correlationId: req.body.correlationId
  });
});

app.use((error, _req, res, _next) => {
  console.error('[course-demo]', error.response && error.response.data ? error.response.data : error.message);
  res.status(500).send('Unexpected demo error. Check the terminal log.');
});

if (require.main === module) {
  initOidc()
    .then(() => app.listen(Number(process.env.PORT || 4000), () => {
      console.log(`Course demo listening at http://localhost:${process.env.PORT || 4000}`);
    }))
    .catch(error => {
      console.error('OIDC initialization failed:', error.message);
      process.exit(1);
    });
}

module.exports = { app };
