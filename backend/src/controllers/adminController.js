const User = require('../models/User');
const { sendSuccess, sendError } = require('../utils/response');

const getUsers = async (req, res, next) => {
  try {
    const users = await User.find().sort({ createdAt: -1 });
    const formatted = users.map((u) => u.toAuthJSON());
    return sendSuccess(res, 'Users retrieved successfully', { users: formatted }, 'USERS_FETCHED', 200);
  } catch (error) {
    next(error);
  }
};

const toggleUserStatus = async (req, res, next) => {
  try {
    const { userId } = req.params;
    const { isActive } = req.body;

    if (typeof isActive !== 'boolean') {
      return sendError(res, 'isActive parameter must be a boolean.', 'INVALID_STATUS', 400);
    }

    const user = await User.findById(userId);
    if (!user) {
      return sendError(res, 'User not found.', 'USER_NOT_FOUND', 404);
    }

    user.isActive = isActive;
    await user.save();

    return sendSuccess(
      res,
      `User account ${isActive ? 'activated' : 'deactivated'} successfully`,
      { user: user.toAuthJSON() },
      'USER_STATUS_UPDATED',
      200
    );
  } catch (error) {
    next(error);
  }
};

module.exports = {
  getUsers,
  toggleUserStatus,
};
