const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const env = require('../config/env');
const RefreshToken = require('../models/RefreshToken');

const generateAccessToken = (user) => {
  return jwt.sign(
    {
      sub: user._id.toString(),
      role: user.role,
    },
    env.jwtAccessSecret,
    { expiresIn: env.jwtAccessExpiresIn }
  );
};

const generateRefreshToken = async (user) => {
  const token = jwt.sign(
    {
      sub: user._id.toString(),
    },
    env.jwtRefreshSecret,
    { expiresIn: env.jwtRefreshExpiresIn }
  );

  const tokenHash = await bcrypt.hash(token, 10);
  const expiresAt = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000); // 30 days

  await RefreshToken.create({
    userId: user._id,
    tokenHash,
    expiresAt,
    isRevoked: false,
  });

  return token;
};

const verifyAccessToken = (token) => {
  try {
    return jwt.verify(token, env.jwtAccessSecret);
  } catch (err) {
    return null;
  }
};

const verifyRefreshToken = async (token) => {
  try {
    const payload = jwt.verify(token, env.jwtRefreshSecret);
    const userId = payload.sub;

    const existingTokens = await RefreshToken.find({
      userId,
      isRevoked: false,
      expiresAt: { $gt: new Date() },
    });

    for (const record of existingTokens) {
      const match = await bcrypt.compare(token, record.tokenHash);
      if (match) {
        return { payload, record };
      }
    }
    return null;
  } catch (err) {
    return null;
  }
};

const revokeRefreshToken = async (token) => {
  try {
    const result = await verifyRefreshToken(token);
    if (result && result.record) {
      result.record.isRevoked = true;
      await result.record.save();
    }
  } catch (err) {
    console.error('Error revoking token:', err);
  }
};

module.exports = {
  generateAccessToken,
  generateRefreshToken,
  verifyAccessToken,
  verifyRefreshToken,
  revokeRefreshToken,
};
