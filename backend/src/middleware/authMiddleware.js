const tokenService = require('../services/tokenService');
const User = require('../models/User');
const { sendError } = require('../utils/response');

const requireAuth = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return sendError(res, 'Authentication token missing or invalid format.', 'UNAUTHORIZED', 401);
    }

    const token = authHeader.split(' ')[1];
    const payload = tokenService.verifyAccessToken(token);

    if (!payload) {
      return sendError(res, 'Access token has expired or is invalid.', 'TOKEN_EXPIRED', 401);
    }

    const user = await User.findById(payload.sub);
    if (!user) {
      return sendError(res, 'User associated with token no longer exists.', 'USER_NOT_FOUND', 401);
    }

    if (!user.isActive) {
      return sendError(res, 'Your account has been deactivated. Please contact support.', 'ACCOUNT_DISABLED', 403);
    }

    req.user = user;
    next();
  } catch (error) {
    return sendError(res, 'Authentication failed.', 'UNAUTHORIZED', 401);
  }
};

const requireRole = (allowedRoles = []) => {
  return (req, res, next) => {
    if (!req.user) {
      return sendError(res, 'Authentication required.', 'UNAUTHORIZED', 401);
    }

    if (!allowedRoles.includes(req.user.role)) {
      return sendError(res, 'You do not have permission to access this resource.', 'FORBIDDEN', 403);
    }

    next();
  };
};

module.exports = {
  requireAuth,
  requireRole,
};
