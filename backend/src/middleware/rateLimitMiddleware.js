const rateLimit = require('express-rate-limit');
const { sendError } = require('../utils/response');

const createLimiter = (maxRequests, windowMinutes, message) => {
  return rateLimit({
    windowMs: windowMinutes * 60 * 1000,
    max: maxRequests,
    standardHeaders: true,
    legacyHeaders: false,
    handler: (req, res) => {
      return sendError(
        res,
        message || 'Too many requests. Please try again later.',
        'RATE_LIMIT_EXCEEDED',
        429
      );
    },
  });
};

const authLimiter = createLimiter(10, 15, 'Too many authentication attempts. Please try again in 15 minutes.');
const otpLimiter = createLimiter(5, 10, 'Too many OTP requests. Please try again in 10 minutes.');
const passwordResetLimiter = createLimiter(3, 15, 'Too many password reset requests. Please try again in 15 minutes.');
const apiLimiter = createLimiter(100, 15, 'Too many requests. Please try again later.');

module.exports = {
  authLimiter,
  otpLimiter,
  passwordResetLimiter,
  apiLimiter,
};
