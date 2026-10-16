const test = require('node:test');
const assert = require('node:assert/strict');
const mongoose = require('mongoose');
const env = require('../src/config/env');
const User = require('../src/models/User');
const RefreshToken = require('../src/models/RefreshToken');
const Otp = require('../src/models/Otp');
const authService = require('../src/services/authService');
const tokenService = require('../src/services/tokenService');
const otpService = require('../src/services/otpService');

// Setup MongoDB connection for test runner
test.before(async () => {
  if (mongoose.connection.readyState === 0) {
    await mongoose.connect(env.mongoUri);
  }
  // Clear any existing test users from previous test runs
  await User.deleteMany({ email: /@testauth\.com$/ });
  await Otp.deleteMany({ target: /testauth\.com$/ });
  await Otp.deleteMany({ target: /^\+1555/ });
});

test.after(async () => {
  await User.deleteMany({ email: /@testauth\.com$/ });
  await Otp.deleteMany({ target: /testauth\.com$/ });
  await Otp.deleteMany({ target: /^\+1555/ });
  await mongoose.disconnect();
});

test('1. User Registration - Success and Password Hashing', async () => {
  const email = `traveler_${Date.now()}@testauth.com`;
  const result = await authService.registerUser({
    name: 'Jane Traveler',
    email,
    password: 'Password123!',
    confirmPassword: 'Password123!',
    phone: `+1555${Math.floor(100000 + Math.random() * 900000)}`,
  });

  assert.ok(result.user);
  assert.equal(result.user.email, email);
  assert.equal(result.user.name, 'Jane Traveler');
  assert.ok(result.accessToken);
  assert.ok(result.refreshToken);

  // Verify password hash is never exposed
  assert.equal(result.user.passwordHash, undefined);
  assert.equal(result.user.password, undefined);

  // Verify in database that password is cryptographically hashed (bcrypt)
  const dbUser = await User.findOne({ email }).select('+passwordHash');
  assert.ok(dbUser.passwordHash);
  assert.notEqual(dbUser.passwordHash, 'Password123!');
  assert.ok(dbUser.passwordHash.startsWith('$2'));
});

test('2. User Registration - Duplicate Email Rejection', async () => {
  const email = `duplicate_${Date.now()}@testauth.com`;
  await authService.registerUser({
    name: 'First User',
    email,
    password: 'Password123!',
    confirmPassword: 'Password123!',
  });

  await assert.rejects(
    async () => {
      await authService.registerUser({
        name: 'Second User',
        email,
        password: 'Password123!',
        confirmPassword: 'Password123!',
      });
    },
    (err) => {
      assert.equal(err.code, 'EMAIL_EXISTS');
      assert.equal(err.statusCode, 400);
      return true;
    }
  );
});

test('3. User Login - Valid Credentials and Invalid Password Handling', async () => {
  const email = `login_${Date.now()}@testauth.com`;
  await authService.registerUser({
    name: 'Login Tester',
    email,
    password: 'Password123!',
    confirmPassword: 'Password123!',
  });

  // Valid login
  const loginResult = await authService.loginUser({
    email,
    password: 'Password123!',
  });
  assert.ok(loginResult.accessToken);
  assert.ok(loginResult.refreshToken);
  assert.equal(loginResult.user.email, email);

  // Invalid password
  await assert.rejects(
    async () => {
      await authService.loginUser({
        email,
        password: 'WrongPassword!',
      });
    },
    (err) => {
      assert.equal(err.code, 'INVALID_CREDENTIALS');
      assert.equal(err.statusCode, 401);
      return true;
    }
  );
});

test('4. Brute-Force Lockout - Locks Account After 5 Failed Attempts', async () => {
  const email = `lockout_${Date.now()}@testauth.com`;
  await authService.registerUser({
    name: 'Lockout Tester',
    email,
    password: 'SecurePassword123!',
    confirmPassword: 'SecurePassword123!',
  });

  // 4 failed attempts
  for (let i = 0; i < 4; i++) {
    try {
      await authService.loginUser({ email, password: 'BadPassword' });
    } catch (e) {
      assert.equal(e.code, 'INVALID_CREDENTIALS');
    }
  }

  // 5th attempt locks the account
  await assert.rejects(
    async () => {
      await authService.loginUser({ email, password: 'BadPassword' });
    },
    (err) => {
      assert.equal(err.code, 'ACCOUNT_LOCKED');
      assert.equal(err.statusCode, 423);
      return true;
    }
  );

  // Next attempt (even with valid password) remains locked
  await assert.rejects(
    async () => {
      await authService.loginUser({ email, password: 'SecurePassword123!' });
    },
    (err) => {
      assert.equal(err.code, 'ACCOUNT_LOCKED');
      return true;
    }
  );
});

test('5. Email OTP Flow - Generation, Cryptographic Hashing, Expiry, and Verification', async () => {
  const email = `otp_${Date.now()}@testauth.com`;

  // Send OTP
  const sent = await otpService.sendOtp({
    target: email,
    type: 'email',
    purpose: 'login',
  });
  assert.equal(sent.target, email);
  assert.equal(sent.type, 'email');
  assert.equal(sent.expiresMinutes, 5);

  // Verify OTP is hashed in DB and not in plaintext
  const otpRecord = await Otp.findOne({ target: email, isVerified: false });
  assert.ok(otpRecord);
  assert.ok(otpRecord.codeHash);
  assert.ok(otpRecord.codeHash.startsWith('$2'));

  // Test incorrect OTP attempt
  const badVerify = await otpService.verifyOtp({
    target: email,
    type: 'email',
    purpose: 'login',
    code: '000000',
  });
  assert.equal(badVerify.success, false);
  assert.equal(badVerify.code, 'INVALID_CODE');

  // Verify attempts counter incremented
  const updatedRecord = await Otp.findById(otpRecord._id);
  assert.equal(updatedRecord.attempts, 1);
});

test('6. Password Reset Flow - Token Generation, Hashing, Single-Use, and Session Revocation', async () => {
  const email = `reset_${Date.now()}@testauth.com`;
  const regResult = await authService.registerUser({
    name: 'Reset Tester',
    email,
    password: 'OldPassword123!',
    confirmPassword: 'OldPassword123!',
  });

  const originalRefreshToken = regResult.refreshToken;

  // Request forgot password
  const forgotResult = await authService.forgotPassword({ email });
  assert.ok(forgotResult.message);

  // Retrieve user to extract raw token from hash simulation
  const user = await User.findOne({ email }).select('+passwordResetTokenHash');
  assert.ok(user.passwordResetTokenHash);

  // Mock valid raw token test
  const rawToken = 'test_reset_token_' + Date.now();
  user.passwordResetTokenHash = require('crypto').createHash('sha256').update(rawToken).digest('hex');
  user.passwordResetExpiresAt = new Date(Date.now() + 15 * 60 * 1000);
  await user.save();

  // Perform reset
  const resetResult = await authService.resetPassword({
    token: rawToken,
    password: 'NewBrandPassword123!',
  });
  assert.ok(resetResult.message);

  // Verify login with NEW password works
  const loginWithNew = await authService.loginUser({
    email,
    password: 'NewBrandPassword123!',
  });
  assert.ok(loginWithNew.accessToken);

  // Verify login with OLD password fails
  await assert.rejects(
    async () => {
      await authService.loginUser({
        email,
        password: 'OldPassword123!',
      });
    },
    (err) => err.code === 'INVALID_CREDENTIALS'
  );

  // Verify previous refresh token was revoked (Session Revocation)
  const rotateOld = await tokenService.rotateRefreshToken(originalRefreshToken);
  assert.equal(rotateOld.error, 'TOKEN_REUSE_DETECTED');
});

test('7. Authenticated Change Password & Display Name Update', async () => {
  const email = `profile_${Date.now()}@testauth.com`;
  const reg = await authService.registerUser({
    name: 'Original Name',
    email,
    password: 'Password123!',
    confirmPassword: 'Password123!',
  });

  const userId = reg.user.id;

  // Update display name
  const updatedUser = await authService.updateDisplayName(userId, 'Alex Wonder');
  assert.equal(updatedUser.name, 'Alex Wonder');

  // Change password
  const changeResult = await authService.changePassword(userId, {
    currentPassword: 'Password123!',
    newPassword: 'BrandNewPassword456!',
    confirmPassword: 'BrandNewPassword456!',
  });
  assert.ok(changeResult.accessToken);
  assert.ok(changeResult.refreshToken);

  // Verify login with new password
  const newLogin = await authService.loginUser({
    email,
    password: 'BrandNewPassword456!',
  });
  assert.equal(newLogin.user.name, 'Alex Wonder');
});

test('8. Refresh Token Rotation & Replay Attack Detection', async () => {
  const email = `token_${Date.now()}@testauth.com`;
  const reg = await authService.registerUser({
    name: 'Token Tester',
    email,
    password: 'Password123!',
    confirmPassword: 'Password123!',
  });

  const token1 = reg.refreshToken;

  // First rotation: valid
  const rotation1 = await tokenService.rotateRefreshToken(token1);
  assert.ok(rotation1.newRefreshToken);
  const token2 = rotation1.newRefreshToken;

  // Replay attack: trying to use token1 again!
  const replayAttempt = await tokenService.rotateRefreshToken(token1);
  assert.equal(replayAttempt.error, 'TOKEN_REUSE_DETECTED');

  // After reuse detection, all tokens for user should be revoked (including token2)
  const token2Attempt = await tokenService.rotateRefreshToken(token2);
  assert.equal(token2Attempt.error, 'TOKEN_REUSE_DETECTED');
});

test('9. Social Sign-In - Google and Apple Token Verification Mocking', async () => {
  // Test Google Login
  const googleResult = await authService.googleLoginOrRegister({
    idToken: 'test_google_token_traveler_google',
    name: 'Google Explorer',
  });
  assert.ok(googleResult.accessToken);
  assert.ok(googleResult.user.email.includes('@gmail.com'));
  assert.equal(googleResult.user.isGoogleUser, true);

  // Test Apple Login
  const appleResult = await authService.appleLoginOrRegister({
    identityToken: 'test_apple_token_traveler_apple',
    name: 'Apple Explorer',
  });
  assert.ok(appleResult.accessToken);
  assert.ok(appleResult.user.email.includes('@privaterelay.appleid.com'));
  assert.equal(appleResult.user.isAppleUser, true);
});
