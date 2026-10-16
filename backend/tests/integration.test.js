const test = require('node:test');
const assert = require('node:assert/strict');
const http = require('node:http');
const mongoose = require('mongoose');
const app = require('../src/app');
const env = require('../src/config/env');
const User = require('../src/models/User');

let server;
let baseUrl;

test.before(async () => {
  if (mongoose.connection.readyState === 0) {
    await mongoose.connect(env.mongoUri);
  }
  await User.deleteMany({ email: /@integration\.com$/ });

  await new Promise((resolve) => {
    server = http.createServer(app);
    server.listen(0, () => {
      const port = server.address().port;
      baseUrl = `http://127.0.0.1:${port}/api`;
      resolve();
    });
  });
});

test.after(async () => {
  await User.deleteMany({ email: /@integration\.com$/ });
  await new Promise((resolve) => server.close(resolve));
  await mongoose.disconnect();
});

test('HTTP Integration - /api/health', async () => {
  const res = await fetch(`${baseUrl}/health`);
  const data = await res.json();
  assert.equal(res.status, 200);
  assert.equal(data.success, true);
  assert.equal(data.status, 'ok');
});

test('HTTP Integration - Complete Authentication Lifecycle', async () => {
  const email = `traveler_${Date.now()}@integration.com`;
  const password = 'Password123!';

  // 1. Register
  const regRes = await fetch(`${baseUrl}/auth/register`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      name: 'Integration Traveler',
      email,
      password,
      confirmPassword: password,
    }),
  });
  const regData = await regRes.json();
  assert.equal(regRes.status, 201);
  assert.equal(regData.success, true);
  assert.ok(regData.data.accessToken);
  assert.ok(regData.data.refreshToken);

  let accessToken = regData.data.accessToken;
  let refreshToken = regData.data.refreshToken;

  // 2. Access Protected /auth/me
  const meRes = await fetch(`${baseUrl}/auth/me`, {
    headers: { Authorization: `Bearer ${accessToken}` },
  });
  const meData = await meRes.json();
  assert.equal(meRes.status, 200);
  assert.equal(meData.data.user.email, email);
  assert.equal(meData.data.user.name, 'Integration Traveler');

  // 3. Update Display Name
  const profileRes = await fetch(`${baseUrl}/auth/profile`, {
    method: 'PATCH',
    headers: {
      Authorization: `Bearer ${accessToken}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ name: 'Captain Explorer' }),
  });
  const profileData = await profileRes.json();
  assert.equal(profileRes.status, 200);
  assert.equal(profileData.data.user.name, 'Captain Explorer');

  // 4. Change Password
  const changeRes = await fetch(`${baseUrl}/auth/change-password`, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${accessToken}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      currentPassword: password,
      newPassword: 'UpdatedPassword456!',
      confirmPassword: 'UpdatedPassword456!',
    }),
  });
  const changeData = await changeRes.json();
  assert.equal(changeRes.status, 200);
  assert.ok(changeData.data.accessToken);
  accessToken = changeData.data.accessToken;
  refreshToken = changeData.data.refreshToken;

  // 5. Rotate Refresh Token
  const refreshRes = await fetch(`${baseUrl}/auth/refresh`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ refreshToken }),
  });
  const refreshData = await refreshRes.json();
  assert.equal(refreshRes.status, 200);
  assert.ok(refreshData.data.accessToken);
  assert.ok(refreshData.data.refreshToken);
  accessToken = refreshData.data.accessToken;
  refreshToken = refreshData.data.refreshToken;

  // 6. Login with new credentials
  const loginRes = await fetch(`${baseUrl}/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      email,
      password: 'UpdatedPassword456!',
    }),
  });
  const loginData = await loginRes.json();
  assert.equal(loginRes.status, 200);
  assert.equal(loginData.data.user.name, 'Captain Explorer');

  // 7. Logout
  const logoutRes = await fetch(`${baseUrl}/auth/logout`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ refreshToken }),
  });
  assert.equal(logoutRes.status, 200);

  // 8. Re-attempting refresh with logged out token should fail
  const oldRefreshRes = await fetch(`${baseUrl}/auth/refresh`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ refreshToken }),
  });
  assert.equal(oldRefreshRes.status, 401);
});

test('HTTP Integration - Forgot Password Sanitized Response', async () => {
  const res = await fetch(`${baseUrl}/auth/forgot-password`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email: 'nonexistent@integration.com' }),
  });
  const data = await res.json();
  assert.equal(res.status, 200);
  assert.equal(data.success, true);
  assert.ok(data.message.includes('instructions have been sent'));
});

test('HTTP Integration - Unauthorized Request Rejection', async () => {
  const res = await fetch(`${baseUrl}/auth/me`, {
    headers: { Authorization: 'Bearer invalid_garbage_token' },
  });
  assert.equal(res.status, 401);
});
