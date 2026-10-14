const bcrypt = require('bcryptjs');
const User = require('../models/User');
const tokenService = require('./tokenService');

const registerUser = async ({ name, email, phone, password }) => {
  const normalizedEmail = email.toLowerCase().trim();

  const existingEmail = await User.findOne({ email: normalizedEmail });
  if (existingEmail) {
    const error = new Error('An account with this email address already exists. Please sign in.');
    error.code = 'EMAIL_EXISTS';
    error.statusCode = 400;
    throw error;
  }

  if (phone) {
    const existingPhone = await User.findOne({ phone: phone.trim() });
    if (existingPhone) {
      const error = new Error('An account with this phone number already exists.');
      error.code = 'PHONE_EXISTS';
      error.statusCode = 400;
      throw error;
    }
  }

  const passwordHash = await bcrypt.hash(password, 10);

  const user = await User.create({
    name: name.trim(),
    email: normalizedEmail,
    phone: phone ? phone.trim() : '',
    passwordHash,
    role: 'user',
    isActive: true,
  });

  const accessToken = tokenService.generateAccessToken(user);
  const refreshToken = await tokenService.generateRefreshToken(user);

  return {
    user: user.toAuthJSON(),
    accessToken,
    refreshToken,
  };
};

const loginUser = async ({ email, password }) => {
  const normalizedEmail = email.toLowerCase().trim();

  const user = await User.findOne({ email: normalizedEmail }).select('+passwordHash');
  if (!user) {
    const error = new Error('Invalid email or password.');
    error.code = 'INVALID_CREDENTIALS';
    error.statusCode = 401;
    throw error;
  }

  if (!user.isActive) {
    const error = new Error('Your account has been deactivated. Please contact support.');
    error.code = 'ACCOUNT_DISABLED';
    error.statusCode = 403;
    throw error;
  }

  const isPasswordValid = await bcrypt.compare(password, user.passwordHash);
  if (!isPasswordValid) {
    const error = new Error('Invalid email or password.');
    error.code = 'INVALID_CREDENTIALS';
    error.statusCode = 401;
    throw error;
  }

  user.lastLoginAt = new Date();
  await user.save();

  const accessToken = tokenService.generateAccessToken(user);
  const refreshToken = await tokenService.generateRefreshToken(user);

  return {
    user: user.toAuthJSON(),
    accessToken,
    refreshToken,
  };
};

const googleLoginOrRegister = async ({ email, name, photoUrl, idToken }) => {
  const normalizedEmail = email ? email.toLowerCase().trim() : `google_${Date.now()}@planmytrip.com`;

  let user = await User.findOne({ email: normalizedEmail });

  if (user) {
    if (!user.isActive) {
      const error = new Error('Your account has been deactivated. Please contact support.');
      error.code = 'ACCOUNT_DISABLED';
      error.statusCode = 403;
      throw error;
    }
    user.lastLoginAt = new Date();
    if (photoUrl && !user.photoUrl) user.photoUrl = photoUrl;
    await user.save();
  } else {
    user = await User.create({
      name: name || 'Google Traveler',
      email: normalizedEmail,
      photoUrl: photoUrl || '',
      isGoogleUser: true,
      role: 'user',
      isActive: true,
      isEmailVerified: true,
    });
  }

  const accessToken = tokenService.generateAccessToken(user);
  const refreshToken = await tokenService.generateRefreshToken(user);

  return {
    user: user.toAuthJSON(),
    accessToken,
    refreshToken,
  };
};

module.exports = {
  registerUser,
  loginUser,
  googleLoginOrRegister,
};
