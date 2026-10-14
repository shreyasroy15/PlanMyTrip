const { z } = require('zod');

const registerSchema = z.object({
  name: z.string().min(2, 'Name must be at least 2 characters'),
  email: z.string().email('Please enter a valid email address'),
  phone: z.string().optional().default(''),
  password: z
    .string()
    .min(6, 'Password must be at least 6 characters long'),
  confirmPassword: z.string(),
}).refine((data) => data.password === data.confirmPassword, {
  message: 'Passwords do not match',
  path: ['confirmPassword'],
});

const loginSchema = z.object({
  email: z.string().email('Please enter a valid email address'),
  password: z.string().min(1, 'Password is required'),
});

const forgotPasswordSchema = z.object({
  email: z.string().email('Please enter a valid email address'),
});

const resetPasswordSchema = z.object({
  token: z.string().min(1, 'Reset token is required'),
  password: z.string().min(6, 'Password must be at least 6 characters long'),
  confirmPassword: z.string(),
}).refine((data) => data.password === data.confirmPassword, {
  message: 'Passwords do not match',
  path: ['confirmPassword'],
});

const sendOtpSchema = z.object({
  phone: z.string().min(6, 'Please enter a valid phone number'),
});

const verifyOtpSchema = z.object({
  phone: z.string().min(6, 'Please enter a valid phone number'),
  otp: z.string().length(6, 'OTP must be exactly 6 digits'),
});

const googleAuthSchema = z.object({
  idToken: z.string().min(1, 'Google ID Token is required'),
  email: z.string().email().optional(),
  name: z.string().optional(),
  photoUrl: z.string().optional(),
});

module.exports = {
  registerSchema,
  loginSchema,
  forgotPasswordSchema,
  resetPasswordSchema,
  sendOtpSchema,
  verifyOtpSchema,
  googleAuthSchema,
};
