const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const env = require('../config/env');
const RefreshToken = require('../models/RefreshToken');
const { logSecurityEvent } = require('./auditService');

const hashToken = (token) => {
  return crypto.createHash('sha256').update(token).digest('hex');
};

const generateAccessToken = (user) => {
  return jwt.sign(
    {
      sub: user._id ? user._id.toString() : user.id,
      email: user.email,
      role: user.role,
    },
    env.jwtAccessSecret,
    { expiresIn: env.jwtAccessExpiresIn }
  );
};

const generateRefreshToken = async (user, req = null) => {
  const rawToken = crypto.randomBytes(40).toString('hex');
  const tokenHash = hashToken(rawToken);
  const expiresAt = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000); // 30 days

  let ipAddress = '';
  let userAgent = '';
  if (req) {
    ipAddress = req.ip || req.headers['x-forwarded-for'] || req.socket?.remoteAddress || '';
    userAgent = req.headers['user-agent'] || '';
  }

  await RefreshToken.create({
    userId: user._id || user.id,
    tokenHash,
    expiresAt,
    isRevoked: false,
    createdByIp: String(ipAddress),
    userAgent: String(userAgent),
  });

  return rawToken;
};

const verifyAccessToken = (token) => {
  try {
    return jwt.verify(token, env.jwtAccessSecret);
  } catch (err) {
    return null;
  }
};

const rotateRefreshToken = async (oldRawToken, req = null) => {
  if (!oldRawToken) return null;

  const oldHash = hashToken(oldRawToken);
  const record = await RefreshToken.findOne({ tokenHash: oldHash });

  if (!record) {
    return { error: 'INVALID_TOKEN' };
  }

  // Token Reuse Detection
  if (record.isRevoked) {
    console.warn(`[Security Alert] Refresh token reuse detected for userId: ${record.userId}`);
    // Revoke all tokens for this user family
    await revokeAllUserTokens(record.userId);
    await logSecurityEvent({
      userId: record.userId,
      action: 'TOKEN_REUSE_DETECTED',
      req,
      metadata: { suspectTokenId: record._id.toString() },
    });
    return { error: 'TOKEN_REUSE_DETECTED' };
  }

  if (record.expiresAt < new Date()) {
    return { error: 'TOKEN_EXPIRED' };
  }

  // Generate new token
  const newRawToken = crypto.randomBytes(40).toString('hex');
  const newHash = hashToken(newRawToken);
  const expiresAt = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000);

  let ipAddress = '';
  let userAgent = '';
  if (req) {
    ipAddress = req.ip || req.headers['x-forwarded-for'] || req.socket?.remoteAddress || '';
    userAgent = req.headers['user-agent'] || '';
  }

  // Mark old token revoked and replaced
  record.isRevoked = true;
  record.revokedAt = new Date();
  record.replacedByTokenHash = newHash;
  await record.save();

  // Create new active token
  await RefreshToken.create({
    userId: record.userId,
    tokenHash: newHash,
    expiresAt,
    isRevoked: false,
    createdByIp: String(ipAddress),
    userAgent: String(userAgent),
  });

  await logSecurityEvent({
    userId: record.userId,
    action: 'TOKEN_ROTATED',
    req,
  });

  return {
    userId: record.userId,
    newRefreshToken: newRawToken,
  };
};

const revokeRefreshToken = async (rawToken) => {
  if (!rawToken) return;
  const hash = hashToken(rawToken);
  await RefreshToken.updateOne(
    { tokenHash: hash, isRevoked: false },
    { isRevoked: true, revokedAt: new Date() }
  );
};

const revokeAllUserTokens = async (userId) => {
  await RefreshToken.updateMany(
    { userId, isRevoked: false },
    { isRevoked: true, revokedAt: new Date() }
  );
};

module.exports = {
  hashToken,
  generateAccessToken,
  generateRefreshToken,
  verifyAccessToken,
  rotateRefreshToken,
  revokeRefreshToken,
  revokeAllUserTokens,
};
