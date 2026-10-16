const mongoose = require('mongoose');

const securityAuditLogSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      default: null,
      index: true,
    },
    email: {
      type: String,
      default: '',
      index: true,
    },
    action: {
      type: String,
      required: true,
      enum: [
        'REGISTER',
        'LOGIN_SUCCESS',
        'LOGIN_FAILED',
        'ACCOUNT_LOCKED',
        'LOGOUT',
        'LOGOUT_ALL',
        'OTP_REQUESTED',
        'OTP_VERIFIED',
        'OTP_FAILED',
        'PASSWORD_RESET_REQUEST',
        'PASSWORD_RESET_SUCCESS',
        'PASSWORD_CHANGED',
        'PROFILE_UPDATED',
        'GOOGLE_LOGIN',
        'APPLE_LOGIN',
        'EMAIL_VERIFIED',
        'TOKEN_ROTATED',
        'TOKEN_REUSE_DETECTED',
        'UNAUTHORIZED_ACCESS_ATTEMPT',
      ],
      index: true,
    },
    ipAddress: {
      type: String,
      default: '',
    },
    userAgent: {
      type: String,
      default: '',
    },
    metadata: {
      type: mongoose.Schema.Types.Mixed,
      default: {},
    },
  },
  {
    timestamps: true,
  }
);

// Auto-expire audit logs after 90 days to comply with data retention policies
securityAuditLogSchema.index({ createdAt: 1 }, { expireAfterSeconds: 90 * 24 * 60 * 60 });

const SecurityAuditLog = mongoose.model('SecurityAuditLog', securityAuditLogSchema);

module.exports = SecurityAuditLog;
