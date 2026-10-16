const dotenv = require('dotenv');
const path = require('path');

dotenv.config({ path: path.join(__dirname, '../../.env') });

module.exports = {
  port: parseInt(process.env.PORT || '5000', 10),
  mongoUri: process.env.MONGODB_URI || 'mongodb://127.0.0.1:27017/planmytrip',
  jwtAccessSecret: process.env.JWT_ACCESS_SECRET || 'planmytrip_access_secret_super_secure_key_2026',
  jwtRefreshSecret: process.env.JWT_REFRESH_SECRET || 'planmytrip_refresh_secret_super_secure_key_2026',
  jwtAccessExpiresIn: process.env.JWT_ACCESS_EXPIRES_IN || '15m',
  jwtRefreshExpiresIn: process.env.JWT_REFRESH_EXPIRES_IN || '30d',
  clientUrl: process.env.CLIENT_URL || 'http://localhost:3000',
  otpExpiresMinutes: parseInt(process.env.OTP_EXPIRES_MINUTES || '10', 10),
  nodeEnv: process.env.NODE_ENV || 'development',

  // Email Configuration (SMTP)
  smtpHost: process.env.SMTP_HOST || '',
  smtpPort: parseInt(process.env.SMTP_PORT || '587', 10),
  smtpUser: process.env.SMTP_USER || '',
  smtpPass: process.env.SMTP_PASS || '',
  emailFromName: process.env.EMAIL_FROM_NAME || 'PlanMyTrip AI',
  emailFromAddress: process.env.EMAIL_FROM_ADDRESS || 'no-reply@planmytrip.com',

  // Google OAuth Configuration
  googleClientId: process.env.GOOGLE_CLIENT_ID || '',

  // Apple Sign In Configuration
  appleClientId: process.env.APPLE_CLIENT_ID || '',
  appleTeamId: process.env.APPLE_TEAM_ID || '',
  appleKeyId: process.env.APPLE_KEY_ID || '',

  // Twilio / SMS Configuration
  twilioAccountSid: process.env.TWILIO_ACCOUNT_SID || '',
  twilioAuthToken: process.env.TWILIO_AUTH_TOKEN || '',
  twilioPhoneNumber: process.env.TWILIO_PHONE_NUMBER || '',
};
