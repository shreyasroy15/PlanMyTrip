const dotenv = require('dotenv');
const path = require('path');

dotenv.config({ path: path.join(__dirname, '../../.env') });

module.exports = {
  port: process.env.PORT || 5000,
  mongoUri: process.env.MONGODB_URI || 'mongodb://127.0.0.1:27017/planmytrip',
  jwtAccessSecret: process.env.JWT_ACCESS_SECRET || 'planmytrip_access_secret_super_secure_key_2026',
  jwtRefreshSecret: process.env.JWT_REFRESH_SECRET || 'planmytrip_refresh_secret_super_secure_key_2026',
  jwtAccessExpiresIn: process.env.JWT_ACCESS_EXPIRES_IN || '15m',
  jwtRefreshExpiresIn: process.env.JWT_REFRESH_EXPIRES_IN || '30d',
  clientUrl: process.env.CLIENT_URL || 'http://localhost:3000',
  otpExpiresMinutes: parseInt(process.env.OTP_EXPIRES_MINUTES || '10', 10),
  nodeEnv: process.env.NODE_ENV || 'development'
};
