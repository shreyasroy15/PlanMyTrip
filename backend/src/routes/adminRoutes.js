const express = require('express');
const router = express.Router();
const adminController = require('../controllers/adminController');
const { requireAuth, requireRole } = require('../middleware/authMiddleware');

// Protected Admin Routes (Requires admin or superAdmin role)
router.use(requireAuth);
router.use(requireRole(['admin', 'superAdmin']));

router.get('/users', adminController.getUsers);
router.patch('/users/:userId/status', adminController.toggleUserStatus);

module.exports = router;
