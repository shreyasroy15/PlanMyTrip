const bcrypt = require('bcryptjs');
const Otp = require('../models/Otp');
const env = require('../config/env');

const generateOtp = () => {
  // Generate 6 digit numeric code
  return Math.floor(100000 + Math.random() * 900000).toString();
};

const sendOtp = async (phone) => {
  // Clear any existing active OTP for phone
  await Otp.deleteMany({ phone });

  const code = env.nodeEnv === 'development' ? '123456' : generateOtp();
  const codeHash = await bcrypt.hash(code, 10);
  const expiresAt = new Date(Date.now() + env.otpExpiresMinutes * 60 * 1000);

  await Otp.create({
    phone,
    codeHash,
    expiresAt,
  });

  console.log(`[OTP Service] OTP for ${phone}: ${code} (Expires in ${env.otpExpiresMinutes} min)`);
  return { phone, expiresMinutes: env.otpExpiresMinutes };
};

const verifyOtp = async (phone, code) => {
  const otpRecord = await Otp.findOne({
    phone,
    isVerified: false,
    expiresAt: { $gt: new Date() },
  });

  if (!otpRecord) {
    return { success: false, message: 'OTP has expired or is invalid. Please request a new one.' };
  }

  if (otpRecord.attempts >= 5) {
    await Otp.deleteOne({ _id: otpRecord._id });
    return { success: false, message: 'Too many invalid attempts. Please request a new OTP.' };
  }

  const isMatch = await bcrypt.compare(code, otpRecord.codeHash);
  if (!isMatch) {
    otpRecord.attempts += 1;
    await otpRecord.save();
    return { success: false, message: 'Invalid OTP code. Please try again.' };
  }

  otpRecord.isVerified = true;
  await otpRecord.save();
  return { success: true };
};

module.exports = {
  sendOtp,
  verifyOtp,
};
