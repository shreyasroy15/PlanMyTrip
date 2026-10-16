const crypto = require('crypto');
const bcrypt = require('bcryptjs');
const Otp = require('../models/Otp');
const env = require('../config/env');
const { sendLoginOtpEmail, sendSignupOtpEmail } = require('./emailService');
const { sendSms } = require('./smsService');
const { logSecurityEvent } = require('./auditService');

const generateSecureOtp = () => {
  return crypto.randomInt(100000, 1000000).toString();
};

const sendOtp = async ({ target, type = 'phone', purpose = 'login', req = null }) => {
  const normalizedTarget = type === 'email' ? target.toLowerCase().trim() : target.trim();

  // Rate-limit check: do not allow sending another OTP within 60 seconds
  const recentOtp = await Otp.findOne({
    target: normalizedTarget,
    type,
    purpose,
    isVerified: false,
    createdAt: { $gt: new Date(Date.now() - 60 * 1000) },
  });

  if (recentOtp) {
    const error = new Error('Please wait at least 60 seconds before requesting a new code.');
    error.code = 'OTP_COOLDOWN';
    error.statusCode = 429;
    throw error;
  }

  // Invalidate any older active OTPs for this target & purpose
  await Otp.deleteMany({ target: normalizedTarget, type, purpose });

  const code = env.nodeEnv === 'development' && process.env.TEST_FIXED_OTP ? '123456' : generateSecureOtp();
  const codeHash = await bcrypt.hash(code, 10);
  const expiresMinutes = 5;
  const expiresAt = new Date(Date.now() + expiresMinutes * 60 * 1000);

  await Otp.create({
    target: normalizedTarget,
    type,
    purpose,
    codeHash,
    expiresAt,
  });

  // Dispatch via appropriate channel
  if (type === 'email') {
    if (purpose === 'verification') {
      await sendSignupOtpEmail(normalizedTarget, code, expiresMinutes);
    } else {
      await sendLoginOtpEmail(normalizedTarget, code, expiresMinutes);
    }
  } else {
    const message = `Your PlanMyTrip AI verification code is ${code}. Valid for ${expiresMinutes} minutes. Never share this code.`;
    await sendSms(normalizedTarget, message);
  }

  await logSecurityEvent({
    email: type === 'email' ? normalizedTarget : '',
    action: 'OTP_REQUESTED',
    req,
    metadata: { type, purpose, target: type === 'email' ? normalizedTarget : normalizedTarget.slice(-4) },
  });

  return {
    target: normalizedTarget,
    type,
    expiresMinutes,
  };
};

const verifyOtp = async ({ target, type = 'phone', purpose = 'login', code, req = null }) => {
  const normalizedTarget = type === 'email' ? target.toLowerCase().trim() : target.trim();

  const otpRecord = await Otp.findOne({
    target: normalizedTarget,
    type,
    purpose,
    isVerified: false,
    expiresAt: { $gt: new Date() },
  });

  if (!otpRecord) {
    await logSecurityEvent({
      email: type === 'email' ? normalizedTarget : '',
      action: 'OTP_FAILED',
      req,
      metadata: { reason: 'EXPIRED_OR_NOT_FOUND', type, purpose },
    });
    return {
      success: false,
      message: 'Verification code has expired or is invalid. Please request a new code.',
      code: 'EXPIRED_OR_INVALID',
    };
  }

  if (otpRecord.attempts >= 5) {
    await Otp.deleteOne({ _id: otpRecord._id });
    await logSecurityEvent({
      email: type === 'email' ? normalizedTarget : '',
      action: 'OTP_FAILED',
      req,
      metadata: { reason: 'MAX_ATTEMPTS_EXCEEDED', type, purpose },
    });
    return {
      success: false,
      message: 'Too many incorrect attempts. For security, please request a new verification code.',
      code: 'TOO_MANY_ATTEMPTS',
    };
  }

  const isMatch = await bcrypt.compare(code, otpRecord.codeHash);
  if (!isMatch) {
    otpRecord.attempts += 1;
    await otpRecord.save();
    await logSecurityEvent({
      email: type === 'email' ? normalizedTarget : '',
      action: 'OTP_FAILED',
      req,
      metadata: { attempts: otpRecord.attempts, type, purpose },
    });
    return {
      success: false,
      message: 'Invalid verification code. Please check and try again.',
      code: 'INVALID_CODE',
    };
  }

  // Mark verified and single-use
  otpRecord.isVerified = true;
  await otpRecord.save();

  await logSecurityEvent({
    email: type === 'email' ? normalizedTarget : '',
    action: 'OTP_VERIFIED',
    req,
    metadata: { type, purpose },
  });

  return { success: true };
};

module.exports = {
  sendOtp,
  verifyOtp,
};
