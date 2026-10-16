const mongoose = require('mongoose');

const userSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: [true, 'Name is required'],
      trim: true,
    },
    email: {
      type: String,
      required: [true, 'Email is required'],
      unique: true,
      lowercase: true,
      trim: true,
      index: true,
    },
    phone: {
      type: String,
      default: '',
      trim: true,
      index: true,
    },
    passwordHash: {
      type: String,
      required: function () {
        // Password hash required unless signed up via Google or Apple
        return !this.isGoogleUser && !this.isAppleUser;
      },
      select: false,
    },
    isGoogleUser: {
      type: Boolean,
      default: false,
    },
    googleId: {
      type: String,
      default: '',
      index: true,
    },
    isAppleUser: {
      type: Boolean,
      default: false,
    },
    appleId: {
      type: String,
      default: '',
      index: true,
    },
    photoUrl: {
      type: String,
      default: '',
    },
    role: {
      type: String,
      enum: ['user', 'admin', 'superAdmin'],
      default: 'user',
      index: true,
    },
    isActive: {
      type: Boolean,
      default: true,
      index: true,
    },
    isEmailVerified: {
      type: Boolean,
      default: false,
    },
    emailVerificationTokenHash: {
      type: String,
      default: null,
      select: false,
    },
    emailVerificationExpiresAt: {
      type: Date,
      default: null,
    },
    isPhoneVerified: {
      type: Boolean,
      default: false,
    },
    passwordResetTokenHash: {
      type: String,
      default: null,
      select: false,
    },
    passwordResetExpiresAt: {
      type: Date,
      default: null,
    },
    failedLoginAttempts: {
      type: Number,
      default: 0,
    },
    lockoutUntil: {
      type: Date,
      default: null,
    },
    lastLoginAt: {
      type: Date,
      default: Date.now,
    },
  },
  {
    timestamps: true,
    toJSON: {
      transform: (doc, ret) => {
        ret.id = ret._id.toString();
        delete ret._id;
        delete ret.__v;
        delete ret.passwordHash;
        delete ret.passwordResetTokenHash;
        delete ret.emailVerificationTokenHash;
        return ret;
      },
    },
  }
);

// Helper to check if account is currently locked
userSchema.methods.isLocked = function () {
  return this.lockoutUntil && this.lockoutUntil > new Date();
};

// Method to format sanitized JSON object for API response
userSchema.methods.toAuthJSON = function () {
  return {
    id: this._id.toString(),
    name: this.name,
    email: this.email,
    phone: this.phone,
    photoUrl: this.photoUrl,
    role: this.role,
    isActive: this.isActive,
    isEmailVerified: this.isEmailVerified,
    isPhoneVerified: this.isPhoneVerified,
    isGoogleUser: this.isGoogleUser,
    isAppleUser: this.isAppleUser,
    hasPassword: Boolean(this.passwordHash || !this.isGoogleUser && !this.isAppleUser),
    createdAt: this.createdAt,
    lastLoginAt: this.lastLoginAt,
  };
};

const User = mongoose.model('User', userSchema);

module.exports = User;
