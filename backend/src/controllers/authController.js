const authService = require('../services/authService');
const tokenService = require('../services/tokenService');
const otpService = require('../services/otpService');
const User = require('../models/User');
const { sendSuccess, sendError } = require('../utils/response');
const {
  registerSchema,
  loginSchema,
  forgotPasswordSchema,
  resetPasswordSchema,
  changePasswordSchema,
  updateProfileSchema,
  sendEmailOtpSchema,
  verifyEmailOtpSchema,
  sendPhoneOtpSchema,
  verifyPhoneOtpSchema,
  googleAuthSchema,
  appleAuthSchema,
  verifyEmailSchema,
} = require('../validators/authValidator');

const register = async (req, res, next) => {
  try {
    const validated = registerSchema.parse(req.body);
    const result = await authService.registerUser(validated, req);
    return sendSuccess(res, 'Account created successfully. Please verify your email.', result, 'REGISTER_SUCCESS', 201);
  } catch (error) {
    next(error);
  }
};

const login = async (req, res, next) => {
  try {
    const validated = loginSchema.parse(req.body);
    const result = await authService.loginUser(validated, req);
    return sendSuccess(res, 'Signed in successfully', result, 'LOGIN_SUCCESS', 200);
  } catch (error) {
    next(error);
  }
};

const refresh = async (req, res, next) => {
  try {
    const { refreshToken } = req.body;
    if (!refreshToken) {
      return sendError(res, 'Refresh token is required.', 'TOKEN_REQUIRED', 400);
    }

    const rotated = await tokenService.rotateRefreshToken(refreshToken, req);

    if (!rotated || rotated.error) {
      const code = rotated?.error || 'INVALID_REFRESH_TOKEN';
      const message = code === 'TOKEN_REUSE_DETECTED'
        ? 'Security compromise detected: token reuse. All active sessions have been revoked. Please sign in again.'
        : 'Session expired or invalid refresh token. Please sign in again.';
      return sendError(res, message, code, 401);
    }

    const user = await User.findById(rotated.userId);
    if (!user || !user.isActive) {
      return sendError(res, 'User account deactivated or unavailable.', 'ACCOUNT_DISABLED', 403);
    }

    const newAccessToken = tokenService.generateAccessToken(user);

    return sendSuccess(
      res,
      'Token refreshed successfully',
      {
        accessToken: newAccessToken,
        refreshToken: rotated.newRefreshToken,
        user: user.toAuthJSON(),
      },
      'REFRESH_SUCCESS',
      200
    );
  } catch (error) {
    next(error);
  }
};

const logout = async (req, res, next) => {
  try {
    const { refreshToken } = req.body;
    if (refreshToken) {
      await tokenService.revokeRefreshToken(refreshToken);
    }
    return sendSuccess(res, 'Signed out successfully', {}, 'LOGOUT_SUCCESS', 200);
  } catch (error) {
    next(error);
  }
};

const logoutAll = async (req, res, next) => {
  try {
    if (req.user) {
      await tokenService.revokeAllUserTokens(req.user._id);
    }
    return sendSuccess(res, 'Signed out from all devices successfully', {}, 'LOGOUT_ALL_SUCCESS', 200);
  } catch (error) {
    next(error);
  }
};

const getMe = async (req, res) => {
  return sendSuccess(
    res,
    'User profile retrieved successfully',
    { user: req.user.toAuthJSON() },
    'PROFILE_SUCCESS',
    200
  );
};

const updateProfile = async (req, res, next) => {
  try {
    const validated = updateProfileSchema.parse(req.body);
    const updatedUser = await authService.updateDisplayName(req.user._id, validated.name, req);
    return sendSuccess(res, 'Profile updated successfully', { user: updatedUser }, 'PROFILE_UPDATED', 200);
  } catch (error) {
    next(error);
  }
};

const changePassword = async (req, res, next) => {
  try {
    const validated = changePasswordSchema.parse(req.body);
    const result = await authService.changePassword(req.user._id, validated, req);
    return sendSuccess(res, 'Password changed successfully', result, 'PASSWORD_CHANGED_SUCCESS', 200);
  } catch (error) {
    next(error);
  }
};

const forgotPassword = async (req, res, next) => {
  try {
    const validated = forgotPasswordSchema.parse(req.body);
    const result = await authService.forgotPassword(validated, req);
    return sendSuccess(res, result.message, {}, 'FORGOT_PASSWORD_SENT', 200);
  } catch (error) {
    next(error);
  }
};

const resetPassword = async (req, res, next) => {
  try {
    const validated = resetPasswordSchema.parse(req.body);
    const result = await authService.resetPassword(validated, req);
    return sendSuccess(res, result.message, {}, 'RESET_PASSWORD_SUCCESS', 200);
  } catch (error) {
    next(error);
  }
};

const verifyEmail = async (req, res, next) => {
  try {
    const validated = verifyEmailSchema.parse(req.body);
    const updatedUser = await authService.verifyEmail(validated.token, req);
    return sendSuccess(res, 'Email verified successfully', { user: updatedUser }, 'EMAIL_VERIFIED_SUCCESS', 200);
  } catch (error) {
    next(error);
  }
};

// Email OTP Endpoints
const sendEmailOtp = async (req, res, next) => {
  try {
    const validated = sendEmailOtpSchema.parse(req.body);
    const result = await otpService.sendOtp({
      target: validated.email,
      type: 'email',
      purpose: validated.purpose,
      req,
    });
    return sendSuccess(res, `Verification code sent to ${validated.email}`, result, 'EMAIL_OTP_SENT', 200);
  } catch (error) {
    next(error);
  }
};

const verifyEmailOtp = async (req, res, next) => {
  try {
    const validated = verifyEmailOtpSchema.parse(req.body);
    const verification = await otpService.verifyOtp({
      target: validated.email,
      type: 'email',
      purpose: validated.purpose,
      code: validated.otp,
      req,
    });

    if (!verification.success) {
      return sendError(res, verification.message, verification.code || 'INVALID_OTP', 400);
    }

    // If OTP is for login, find or create user and return tokens
    let user = await User.findOne({ email: validated.email });
    if (!user) {
      user = await User.create({
        name: `Traveler ${validated.email.split('@')[0]}`,
        email: validated.email,
        isEmailVerified: true,
        role: 'user',
        isActive: true,
      });
    } else {
      user.isEmailVerified = true;
      user.lastLoginAt = new Date();
      await user.save();
    }

    const accessToken = tokenService.generateAccessToken(user);
    const refreshToken = await tokenService.generateRefreshToken(user, req);

    return sendSuccess(
      res,
      'Email OTP verified successfully',
      {
        user: user.toAuthJSON(),
        accessToken,
        refreshToken,
      },
      'EMAIL_OTP_VERIFIED',
      200
    );
  } catch (error) {
    next(error);
  }
};

// Phone OTP Endpoints
const sendOtp = async (req, res, next) => {
  try {
    const validated = sendPhoneOtpSchema.parse(req.body);
    const result = await otpService.sendOtp({
      target: validated.phone,
      type: 'phone',
      purpose: 'login',
      req,
    });
    return sendSuccess(res, `Verification code sent to ${validated.phone}`, result, 'OTP_SENT', 200);
  } catch (error) {
    next(error);
  }
};

const verifyOtp = async (req, res, next) => {
  try {
    const validated = verifyPhoneOtpSchema.parse(req.body);
    const verification = await otpService.verifyOtp({
      target: validated.phone,
      type: 'phone',
      purpose: 'login',
      code: validated.otp,
      req,
    });

    if (!verification.success) {
      return sendError(res, verification.message, verification.code || 'INVALID_OTP', 400);
    }

    let user = await User.findOne({ phone: validated.phone });
    if (!user) {
      user = await User.create({
        name: `Traveler ${validated.phone.slice(-4)}`,
        email: `phone_${Date.now()}@planmytrip.com`,
        phone: validated.phone,
        isPhoneVerified: true,
        role: 'user',
        isActive: true,
      });
    } else {
      user.isPhoneVerified = true;
      user.lastLoginAt = new Date();
      await user.save();
    }

    const accessToken = tokenService.generateAccessToken(user);
    const refreshToken = await tokenService.generateRefreshToken(user, req);

    return sendSuccess(
      res,
      'Phone verified successfully',
      {
        user: user.toAuthJSON(),
        accessToken,
        refreshToken,
      },
      'OTP_VERIFIED',
      200
    );
  } catch (error) {
    next(error);
  }
};

const googleAuth = async (req, res, next) => {
  try {
    const validated = googleAuthSchema.parse(req.body);
    const result = await authService.googleLoginOrRegister(validated, req);
    return sendSuccess(res, 'Google authentication successful', result, 'GOOGLE_AUTH_SUCCESS', 200);
  } catch (error) {
    next(error);
  }
};

const appleAuth = async (req, res, next) => {
  try {
    const validated = appleAuthSchema.parse(req.body);
    const result = await authService.appleLoginOrRegister(validated, req);
    return sendSuccess(res, 'Apple authentication successful', result, 'APPLE_AUTH_SUCCESS', 200);
  } catch (error) {
    next(error);
  }
};

module.exports = {
  register,
  login,
  refresh,
  logout,
  logoutAll,
  getMe,
  updateProfile,
  changePassword,
  forgotPassword,
  resetPassword,
  verifyEmail,
  sendEmailOtp,
  verifyEmailOtp,
  sendOtp,
  verifyOtp,
  googleAuth,
  appleAuth,
};
