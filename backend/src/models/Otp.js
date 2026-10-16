const mongoose = require('mongoose');

const otpSchema = new mongoose.Schema(
  {
    target: {
      type: String,
      required: true,
      trim: true,
      index: true,
    },
    type: {
      type: String,
      enum: ['email', 'phone'],
      required: true,
      default: 'phone',
      index: true,
    },
    purpose: {
      type: String,
      enum: ['login', 'verification', 'password_reset'],
      required: true,
      default: 'login',
      index: true,
    },
    codeHash: {
      type: String,
      required: true,
    },
    expiresAt: {
      type: Date,
      required: true,
      index: { expires: '10m' }, // TTL index
    },
    attempts: {
      type: Number,
      default: 0,
    },
    isVerified: {
      type: Boolean,
      default: false,
    },
  },
  {
    timestamps: true,
  }
);

// Compound index for querying active unverified OTPs efficiently
otpSchema.index({ target: 1, type: 1, purpose: 1, isVerified: 1 });

const Otp = mongoose.model('Otp', otpSchema);

module.exports = Otp;
