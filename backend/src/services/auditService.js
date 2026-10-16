const SecurityAuditLog = require('../models/SecurityAuditLog');

const logSecurityEvent = async ({ userId = null, email = '', action, req = null, metadata = {} }) => {
  try {
    let ipAddress = '';
    let userAgent = '';

    if (req) {
      ipAddress = req.ip || req.headers['x-forwarded-for'] || req.socket?.remoteAddress || '';
      userAgent = req.headers['user-agent'] || '';
    }

    // Safety sanitize metadata to ensure no passwords, secrets, or tokens are ever saved
    const safeMetadata = { ...metadata };
    delete safeMetadata.password;
    delete safeMetadata.passwordHash;
    delete safeMetadata.confirmPassword;
    delete safeMetadata.token;
    delete safeMetadata.refreshToken;
    delete safeMetadata.accessToken;
    delete safeMetadata.idToken;
    delete safeMetadata.otp;

    await SecurityAuditLog.create({
      userId,
      email: email ? email.toLowerCase().trim() : '',
      action,
      ipAddress: String(ipAddress),
      userAgent: String(userAgent),
      metadata: safeMetadata,
    });
  } catch (error) {
    // Non-blocking error for auditing
    console.error('[AuditService] Error saving audit log:', error.message);
  }
};

module.exports = { logSecurityEvent };
