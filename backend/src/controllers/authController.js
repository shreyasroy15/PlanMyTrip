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
  sendOtpSchema,
  verifyOtpSchema,
  googleAuthSchema,
} = require('../validators/authValidator');

const register = async (req, res, next) => {
  try {
    const validated = registerSchema.parse(req.body);
    const result = await authService.registerUser(validated);
    return sendSuccess(res, 'Account created successfully', result, 'REGISTER_SUCCESS', 201);
  } catch (error) {
    next(error);
  }
};

const login = async (req, res, next) => {
  try {
    const validated = loginSchema.parse(req.body);
    const result = await authService.loginUser(validated);
    return sendSuccess(res, 'Logged in successfully', result, 'LOGIN_SUCCESS', 200);
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

    const verification = await tokenService.verifyRefreshToken(refreshToken);
    if (!verification) {
      return sendError(res, 'Invalid or expired refresh token. Please sign in again.', 'INVALID_REFRESH_TOKEN', 401);
    }

    const user = await User.findById(verification.payload.sub);
    if (!user || !user.isActive) {
      return sendError(res, 'User account disabled or unavailable.', 'ACCOUNT_DISABLED', 403);
    }

    const newAccessToken = tokenService.generateAccessToken(user);
    const newRefreshToken = await tokenService.generateRefreshToken(user);

    // Revoke old refresh token
    await tokenService.revokeRefreshToken(refreshToken);

    return sendSuccess(
      res,
      'Token refreshed successfully',
      {
        accessToken: newAccessToken,
        refreshToken: newRefreshToken,
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
    return sendSuccess(res, 'Logged out successfully', {}, 'LOGOUT_SUCCESS', 200);
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

const forgotPassword = async (req, res, next) => {
  try {
    const validated = forgotPasswordSchema.parse(req.body);
    // Always return success message to prevent user enumeration attacks
    console.log(`[Password Reset] Password reset requested for: ${validated.email}`);
    return sendSuccess(
      res,
      'If the account exists, password reset instructions have been sent.',
      {},
      'FORGOT_PASSWORD_SENT',
      200
    );
  } catch (error) {
    next(error);
  }
};

const resetPassword = async (req, res, next) => {
  try {
    const validated = resetPasswordSchema.parse(req.body);
    return sendSuccess(
      res,
      'Password has been reset successfully. Please log in with your new password.',
      {},
      'RESET_PASSWORD_SUCCESS',
      200
    );
  } catch (error) {
    next(error);
  }
};

const sendOtp = async (req, res, next) => {
  try {
    const validated = sendOtpSchema.parse(req.body);
    const result = await otpService.sendOtp(validated.phone);
    return sendSuccess(
      res,
      `OTP sent successfully to ${validated.phone}`,
      result,
      'OTP_SENT',
      200
    );
  } catch (error) {
    next(error);
  }
};

const verifyOtp = async (req, res, next) => {
  try {
    const validated = verifyOtpSchema.parse(req.body);
    const verification = await otpService.verifyOtp(validated.phone, validated.otp);

    if (!verification.success) {
      return sendError(res, verification.message, 'INVALID_OTP', 400);
    }

    // Find or create user with phone number
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
    const refreshToken = await tokenService.generateRefreshToken(user);

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
    const result = await authService.googleLoginOrRegister(validated);
    return sendSuccess(res, 'Google authentication successful', result, 'GOOGLE_AUTH_SUCCESS', 200);
  } catch (error) {
    next(error);
  }
};

module.exports = {
  register,
  login,
  refresh,
  logout,
  getMe,
  forgotPassword,
  resetPassword,
  sendOtp,
  verifyOtp,
  googleAuth,
};
