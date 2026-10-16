const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController');
const { requireAuth } = require('../middleware/authMiddleware');
const {
  authLimiter,
  otpLimiter,
  passwordResetLimiter,
} = require('../middleware/rateLimitMiddleware');

// Public Registration & Login
router.post('/register', authLimiter, authController.register);
router.post('/login', authLimiter, authController.login);
router.post('/refresh', authController.refresh);
router.post('/logout', authController.logout);

// Password Recovery & Verification
router.post('/forgot-password', passwordResetLimiter, authController.forgotPassword);
router.post('/reset-password', passwordResetLimiter, authController.resetPassword);
router.post('/verify-email', authController.verifyEmail);

// Email OTP Authentication
router.post('/send-email-otp', otpLimiter, authController.sendEmailOtp);
router.post('/verify-email-otp', otpLimiter, authController.verifyEmailOtp);

// Phone OTP Authentication
router.post('/send-otp', otpLimiter, authController.sendOtp);
router.post('/verify-otp', otpLimiter, authController.verifyOtp);

// Social Identity Providers
router.post('/google', authLimiter, authController.googleAuth);
router.post('/apple', authLimiter, authController.appleAuth);

// Protected User Endpoints
router.get('/me', requireAuth, authController.getMe);
router.patch('/profile', requireAuth, authController.updateProfile);
router.post('/change-password', requireAuth, authController.changePassword);
router.post('/logout-all', requireAuth, authController.logoutAll);

module.exports = router;
