const crypto = require('crypto');
const bcrypt = require('bcryptjs');
const User = require('../models/User');
const tokenService = require('./tokenService');
const emailService = require('./emailService');
const { logSecurityEvent } = require('./auditService');
const { verifyGoogleToken } = require('./googleAuthService');
const { verifyAppleToken } = require('./appleAuthService');

const hashSecret = (secret) => {
  return crypto.createHash('sha256').update(secret).digest('hex');
};

const registerUser = async ({ name, email, phone, password }, req = null) => {
  const normalizedEmail = email.toLowerCase().trim();

  const existingEmail = await User.findOne({ email: normalizedEmail });
  if (existingEmail) {
    const error = new Error('An account with this email address already exists. Please sign in.');
    error.code = 'EMAIL_EXISTS';
    error.statusCode = 400;
    throw error;
  }

  if (phone && phone.trim()) {
    const existingPhone = await User.findOne({ phone: phone.trim() });
    if (existingPhone) {
      const error = new Error('An account with this phone number already exists.');
      error.code = 'PHONE_EXISTS';
      error.statusCode = 400;
      throw error;
    }
  }

  const passwordHash = await bcrypt.hash(password, 10);

  // Generate Email Verification Token
  const rawVerificationToken = crypto.randomBytes(32).toString('hex');
  const emailVerificationTokenHash = hashSecret(rawVerificationToken);
  const emailVerificationExpiresAt = new Date(Date.now() + 24 * 60 * 60 * 1000); // 24 hours

  const user = await User.create({
    name: name.trim(),
    email: normalizedEmail,
    phone: phone ? phone.trim() : '',
    passwordHash,
    role: 'user',
    isActive: true,
    isEmailVerified: false,
    emailVerificationTokenHash,
    emailVerificationExpiresAt,
  });

  // Dispatch Welcome & Verification Emails
  await emailService.sendWelcomeEmail(user);
  await emailService.sendEmailVerification(user, rawVerificationToken);

  const accessToken = tokenService.generateAccessToken(user);
  const refreshToken = await tokenService.generateRefreshToken(user, req);

  await logSecurityEvent({
    userId: user._id,
    email: user.email,
    action: 'REGISTER',
    req,
  });

  return {
    user: user.toAuthJSON(),
    accessToken,
    refreshToken,
    emailVerificationRequired: true,
  };
};

const loginUser = async ({ email, password, rememberMe = false }, req = null) => {
  const normalizedEmail = email.toLowerCase().trim();

  const user = await User.findOne({ email: normalizedEmail }).select(
    '+passwordHash +lockoutUntil +failedLoginAttempts'
  );

  if (!user) {
    await logSecurityEvent({
      email: normalizedEmail,
      action: 'LOGIN_FAILED',
      req,
      metadata: { reason: 'USER_NOT_FOUND' },
    });
    const error = new Error('Invalid email or password.');
    error.code = 'INVALID_CREDENTIALS';
    error.statusCode = 401;
    throw error;
  }

  // Account Lockout Check
  if (user.isLocked()) {
    const remainingMinutes = Math.ceil((user.lockoutUntil.getTime() - Date.now()) / (60 * 1000));
    await logSecurityEvent({
      userId: user._id,
      email: user.email,
      action: 'LOGIN_FAILED',
      req,
      metadata: { reason: 'ACCOUNT_LOCKED', remainingMinutes },
    });
    const error = new Error(`Account temporarily locked due to too many failed attempts. Try again in ${remainingMinutes} minute(s).`);
    error.code = 'ACCOUNT_LOCKED';
    error.statusCode = 423;
    throw error;
  }

  if (!user.isActive) {
    const error = new Error('Your account has been deactivated. Please contact support.');
    error.code = 'ACCOUNT_DISABLED';
    error.statusCode = 403;
    throw error;
  }

  // Password comparison
  if (!user.passwordHash) {
    // Account was created via external social login
    const error = new Error('This account was created with Google or Apple. Please sign in using your social provider or reset your password.');
    error.code = 'OAUTH_ACCOUNT_REQUIRES_SOCIAL_LOGIN';
    error.statusCode = 400;
    throw error;
  }

  const isPasswordValid = await bcrypt.compare(password, user.passwordHash);
  if (!isPasswordValid) {
    user.failedLoginAttempts = (user.failedLoginAttempts || 0) + 1;
    if (user.failedLoginAttempts >= 5) {
      user.lockoutUntil = new Date(Date.now() + 15 * 60 * 1000); // 15 minutes lockout
      await user.save();
      await logSecurityEvent({
        userId: user._id,
        email: user.email,
        action: 'ACCOUNT_LOCKED',
        req,
      });
      const error = new Error('Too many invalid login attempts. Your account has been temporarily locked for 15 minutes.');
      error.code = 'ACCOUNT_LOCKED';
      error.statusCode = 423;
      throw error;
    }
    await user.save();

    await logSecurityEvent({
      userId: user._id,
      email: user.email,
      action: 'LOGIN_FAILED',
      req,
      metadata: { attempts: user.failedLoginAttempts },
    });

    const error = new Error('Invalid email or password.');
    error.code = 'INVALID_CREDENTIALS';
    error.statusCode = 401;
    throw error;
  }

  // Login Success: Reset lockout tracking
  user.failedLoginAttempts = 0;
  user.lockoutUntil = null;
  user.lastLoginAt = new Date();
  await user.save();

  const accessToken = tokenService.generateAccessToken(user);
  const refreshToken = await tokenService.generateRefreshToken(user, req);

  await logSecurityEvent({
    userId: user._id,
    email: user.email,
    action: 'LOGIN_SUCCESS',
    req,
    metadata: { rememberMe },
  });

  return {
    user: user.toAuthJSON(),
    accessToken,
    refreshToken,
  };
};

const forgotPassword = async ({ email }, req = null) => {
  const normalizedEmail = email.toLowerCase().trim();
  const user = await User.findOne({ email: normalizedEmail });

  if (user && user.isActive) {
    const rawResetToken = crypto.randomBytes(32).toString('hex');
    const tokenHash = hashSecret(rawResetToken);
    user.passwordResetTokenHash = tokenHash;
    user.passwordResetExpiresAt = new Date(Date.now() + 15 * 60 * 1000); // 15 min expiry
    await user.save();

    await emailService.sendPasswordResetEmail(user, rawResetToken);

    await logSecurityEvent({
      userId: user._id,
      email: user.email,
      action: 'PASSWORD_RESET_REQUEST',
      req,
    });
  } else {
    // Generic log without revealing nonexistence
    console.log(`[ForgotPassword] Request for unverified or non-existent email: ${normalizedEmail}`);
  }

  return {
    message: 'If the account exists, password reset instructions have been sent.',
  };
};

const resetPassword = async ({ token, password }, req = null) => {
  const tokenHash = hashSecret(token);

  const user = await User.findOne({
    passwordResetTokenHash: tokenHash,
    passwordResetExpiresAt: { $gt: new Date() },
  }).select('+passwordResetTokenHash +passwordHash');

  if (!user) {
    const error = new Error('Password reset token is invalid or has expired. Please request a new link.');
    error.code = 'INVALID_RESET_TOKEN';
    error.statusCode = 400;
    throw error;
  }

  const passwordHash = await bcrypt.hash(password, 10);
  user.passwordHash = passwordHash;
  user.passwordResetTokenHash = null;
  user.passwordResetExpiresAt = null;
  user.failedLoginAttempts = 0;
  user.lockoutUntil = null;
  await user.save();

  // Revoke all existing sessions for security
  await tokenService.revokeAllUserTokens(user._id);

  // Send password changed security notification
  await emailService.sendPasswordChangedAlert(user);

  await logSecurityEvent({
    userId: user._id,
    email: user.email,
    action: 'PASSWORD_RESET_SUCCESS',
    req,
  });

  return {
    message: 'Password has been reset successfully. Please sign in with your new password.',
  };
};

const changePassword = async (userId, { currentPassword, newPassword }, req = null) => {
  const user = await User.findById(userId).select('+passwordHash');
  if (!user) {
    const error = new Error('User not found.');
    error.code = 'USER_NOT_FOUND';
    error.statusCode = 404;
    throw error;
  }

  if (user.passwordHash) {
    const isCurrentValid = await bcrypt.compare(currentPassword, user.passwordHash);
    if (!isCurrentValid) {
      const error = new Error('Current password does not match.');
      error.code = 'INVALID_CURRENT_PASSWORD';
      error.statusCode = 400;
      throw error;
    }
  }

  const newHash = await bcrypt.hash(newPassword, 10);
  user.passwordHash = newHash;
  await user.save();

  // Revoke old refresh tokens and generate new pair for current session
  await tokenService.revokeAllUserTokens(user._id);
  const newAccessToken = tokenService.generateAccessToken(user);
  const newRefreshToken = await tokenService.generateRefreshToken(user, req);

  await emailService.sendPasswordChangedAlert(user);

  await logSecurityEvent({
    userId: user._id,
    email: user.email,
    action: 'PASSWORD_CHANGED',
    req,
  });

  return {
    user: user.toAuthJSON(),
    accessToken: newAccessToken,
    refreshToken: newRefreshToken,
  };
};

const updateDisplayName = async (userId, name, req = null) => {
  const user = await User.findById(userId);
  if (!user) {
    const error = new Error('User not found.');
    error.code = 'USER_NOT_FOUND';
    error.statusCode = 404;
    throw error;
  }

  user.name = name.trim();
  await user.save();

  await logSecurityEvent({
    userId: user._id,
    email: user.email,
    action: 'PROFILE_UPDATED',
    req,
    metadata: { updatedField: 'name' },
  });

  return user.toAuthJSON();
};

const verifyEmail = async (token, req = null) => {
  const tokenHash = hashSecret(token);

  const user = await User.findOne({
    emailVerificationTokenHash: tokenHash,
    emailVerificationExpiresAt: { $gt: new Date() },
  });

  if (!user) {
    const error = new Error('Email verification link is invalid or has expired.');
    error.code = 'INVALID_VERIFICATION_TOKEN';
    error.statusCode = 400;
    throw error;
  }

  user.isEmailVerified = true;
  user.emailVerificationTokenHash = null;
  user.emailVerificationExpiresAt = null;
  await user.save();

  await logSecurityEvent({
    userId: user._id,
    email: user.email,
    action: 'EMAIL_VERIFIED',
    req,
  });

  return user.toAuthJSON();
};

const googleLoginOrRegister = async ({ idToken, name, photoUrl }, req = null) => {
  const verifiedGoogle = await verifyGoogleToken(idToken);
  const normalizedEmail = verifiedGoogle.email.toLowerCase().trim();

  let user = await User.findOne({
    $or: [{ email: normalizedEmail }, { googleId: verifiedGoogle.sub }],
  });

  if (user) {
    if (!user.isActive) {
      const error = new Error('Your account has been deactivated. Please contact support.');
      error.code = 'ACCOUNT_DISABLED';
      error.statusCode = 403;
      throw error;
    }
    user.googleId = verifiedGoogle.sub;
    user.isGoogleUser = true;
    user.isEmailVerified = true;
    user.lastLoginAt = new Date();
    if (verifiedGoogle.picture && !user.photoUrl) {
      user.photoUrl = verifiedGoogle.picture;
    }
    await user.save();
  } else {
    user = await User.create({
      name: name || verifiedGoogle.name || 'Google Traveler',
      email: normalizedEmail,
      googleId: verifiedGoogle.sub,
      photoUrl: photoUrl || verifiedGoogle.picture || '',
      isGoogleUser: true,
      isEmailVerified: true,
      role: 'user',
      isActive: true,
    });
    await emailService.sendWelcomeEmail(user);
  }

  const accessToken = tokenService.generateAccessToken(user);
  const refreshToken = await tokenService.generateRefreshToken(user, req);

  await logSecurityEvent({
    userId: user._id,
    email: user.email,
    action: 'GOOGLE_LOGIN',
    req,
  });

  return {
    user: user.toAuthJSON(),
    accessToken,
    refreshToken,
  };
};

const appleLoginOrRegister = async ({ identityToken, rawNonce, name }, req = null) => {
  const verifiedApple = await verifyAppleToken(identityToken, rawNonce);

  let user = null;
  if (verifiedApple.email) {
    user = await User.findOne({
      $or: [{ email: verifiedApple.email }, { appleId: verifiedApple.sub }],
    });
  } else {
    user = await User.findOne({ appleId: verifiedApple.sub });
  }

  if (user) {
    if (!user.isActive) {
      const error = new Error('Your account has been deactivated. Please contact support.');
      error.code = 'ACCOUNT_DISABLED';
      error.statusCode = 403;
      throw error;
    }
    user.appleId = verifiedApple.sub;
    user.isAppleUser = true;
    user.lastLoginAt = new Date();
    await user.save();
  } else {
    const userEmail = verifiedApple.email || `apple_${verifiedApple.sub.slice(0, 10)}@privaterelay.appleid.com`;
    user = await User.create({
      name: name || 'Apple Traveler',
      email: userEmail,
      appleId: verifiedApple.sub,
      isAppleUser: true,
      isEmailVerified: true,
      role: 'user',
      isActive: true,
    });
    await emailService.sendWelcomeEmail(user);
  }

  const accessToken = tokenService.generateAccessToken(user);
  const refreshToken = await tokenService.generateRefreshToken(user, req);

  await logSecurityEvent({
    userId: user._id,
    email: user.email,
    action: 'APPLE_LOGIN',
    req,
  });

  return {
    user: user.toAuthJSON(),
    accessToken,
    refreshToken,
  };
};

module.exports = {
  registerUser,
  loginUser,
  forgotPassword,
  resetPassword,
  changePassword,
  updateDisplayName,
  verifyEmail,
  googleLoginOrRegister,
  appleLoginOrRegister,
};
