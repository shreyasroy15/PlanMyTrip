const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController');
const { requireAuth } = require('../middleware/authMiddleware');
const {
  authLimiter,
  otpLimiter,
  passwordResetLimiter,
} = require('../middleware/rateLimitMiddleware');

// Public Auth Endpoints
router.post('/register', authLimiter, authController.register);
router.post('/login', authLimiter, authController.login);
router.post('/refresh', authController.refresh);
router.post('/logout', authController.logout);

router.post('/forgot-password', passwordResetLimiter, authController.forgotPassword);
router.post('/reset-password', passwordResetLimiter, authController.resetPassword);

router.post('/send-otp', otpLimiter, authController.sendOtp);
router.post('/verify-otp', otpLimiter, authController.verifyOtp);

router.post('/google', authLimiter, authController.googleAuth);

// Protected Auth Endpoint
router.get('/me', requireAuth, authController.getMe);

module.exports = router;
