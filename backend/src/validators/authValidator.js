const { z } = require('zod');

// Password policy: At least 6 characters (recommended 8+), non-empty
const passwordPolicy = z
  .string()
  .min(6, 'Password must be at least 6 characters long')
  .max(128, 'Password cannot exceed 128 characters');

const registerSchema = z
  .object({
    name: z.string().trim().min(2, 'Name must be at least 2 characters long').max(100),
    email: z.string().trim().email('Please enter a valid email address').toLowerCase(),
    phone: z.string().trim().optional().default(''),
    password: passwordPolicy,
    confirmPassword: z.string(),
    termsAccepted: z.boolean().optional().default(true),
  })
  .refine((data) => data.password === data.confirmPassword, {
    message: 'Passwords do not match',
    path: ['confirmPassword'],
  });

const loginSchema = z.object({
  email: z.string().trim().email('Please enter a valid email address').toLowerCase(),
  password: z.string().min(1, 'Password is required'),
  rememberMe: z.boolean().optional().default(false),
});

const forgotPasswordSchema = z.object({
  email: z.string().trim().email('Please enter a valid email address').toLowerCase(),
});

const resetPasswordSchema = z
  .object({
    token: z.string().min(1, 'Password reset token is required'),
    email: z.string().trim().email().toLowerCase().optional(),
    password: passwordPolicy,
    confirmPassword: z.string(),
  })
  .refine((data) => data.password === data.confirmPassword, {
    message: 'Passwords do not match',
    path: ['confirmPassword'],
  });

const changePasswordSchema = z
  .object({
    currentPassword: z.string().min(1, 'Current password is required'),
    newPassword: passwordPolicy,
    confirmPassword: z.string(),
  })
  .refine((data) => data.newPassword === data.confirmPassword, {
    message: 'New passwords do not match',
    path: ['confirmPassword'],
  })
  .refine((data) => data.currentPassword !== data.newPassword, {
    message: 'New password must be different from current password',
    path: ['newPassword'],
  });

const updateProfileSchema = z.object({
  name: z.string().trim().min(2, 'Name must be at least 2 characters long').max(100),
});

const sendEmailOtpSchema = z.object({
  email: z.string().trim().email('Please enter a valid email address').toLowerCase(),
  purpose: z.enum(['login', 'verification', 'password_reset']).optional().default('login'),
});

const verifyEmailOtpSchema = z.object({
  email: z.string().trim().email('Please enter a valid email address').toLowerCase(),
  otp: z.string().trim().length(6, 'Verification code must be exactly 6 digits'),
  purpose: z.enum(['login', 'verification', 'password_reset']).optional().default('login'),
});

const sendPhoneOtpSchema = z.object({
  phone: z.string().trim().min(6, 'Please enter a valid phone number with country code'),
});

const verifyPhoneOtpSchema = z.object({
  phone: z.string().trim().min(6, 'Please enter a valid phone number with country code'),
  otp: z.string().trim().length(6, 'Verification code must be exactly 6 digits'),
});

const googleAuthSchema = z.object({
  idToken: z.string().min(1, 'Google ID Token is required'),
  email: z.string().email().optional(),
  name: z.string().optional(),
  photoUrl: z.string().optional(),
});

const appleAuthSchema = z.object({
  identityToken: z.string().min(1, 'Apple Identity Token is required'),
  rawNonce: z.string().optional(),
  name: z.string().optional(),
});

const verifyEmailSchema = z.object({
  token: z.string().min(1, 'Verification token is required'),
  email: z.string().trim().email().toLowerCase().optional(),
});

module.exports = {
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
};
