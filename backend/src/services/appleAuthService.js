const jwt = require('jsonwebtoken');
const jwksClient = require('jwks-rsa');
const env = require('../config/env');

const client = jwksClient({
  jwksUri: 'https://appleid.apple.com/auth/keys',
  cache: true,
  cacheMaxAge: 86400000, // 24 hours
  rateLimit: true,
});

const getAppleSigningKey = (header, callback) => {
  client.getSigningKey(header.kid, (err, key) => {
    if (err) {
      return callback(err);
    }
    const signingKey = key.getPublicKey();
    callback(null, signingKey);
  });
};

const verifyAppleToken = async (identityToken, rawNonce = null) => {
  if (!identityToken) {
    throw new Error('Apple identity token is required');
  }

  // Support test environment simulated tokens
  if (identityToken.startsWith('test_apple_token_') && (process.env.NODE_ENV === 'test' || env.nodeEnv === 'development')) {
    const email = identityToken.replace('test_apple_token_', '') + '@privaterelay.appleid.com';
    return {
      sub: `apple_sub_${Date.now()}`,
      email,
      emailVerified: true,
    };
  }

  return new Promise((resolve, reject) => {
    jwt.verify(
      identityToken,
      getAppleSigningKey,
      {
        issuer: 'https://appleid.apple.com',
        audience: env.appleClientId ? env.appleClientId : undefined,
        algorithms: ['RS256'],
      },
      (err, decoded) => {
        if (err) {
          console.error('[AppleAuth] Token verification failed:', err.message);
          const error = new Error('Invalid Apple identity token.');
          error.code = 'INVALID_APPLE_TOKEN';
          error.statusCode = 401;
          return reject(error);
        }

        if (rawNonce && decoded.nonce && decoded.nonce !== rawNonce) {
          const error = new Error('Apple nonce validation mismatch.');
          error.code = 'INVALID_NONCE';
          error.statusCode = 401;
          return reject(error);
        }

        resolve({
          sub: decoded.sub,
          email: decoded.email ? decoded.email.toLowerCase().trim() : null,
          emailVerified: Boolean(decoded.email_verified),
          isPrivateEmail: decoded.is_private_email === 'true' || Boolean(decoded.is_private_email),
        });
      }
    );
  });
};

module.exports = { verifyAppleToken };
