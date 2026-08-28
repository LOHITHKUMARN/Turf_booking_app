const express = require('express');
const {
    getAllTurfs,
    updateTurfStatus,
    getAllUsers,
    updateUserStatus,
    getDashboardStats,
    getAuditLogs,
    getAllPayouts,
    updatePayoutStatus,
    deleteUser
} = require('../controllers/adminController');
const { protect } = require('../middlewares/authMiddleware');
const roleGuard = require('../middlewares/roleGuard');

const router = express.Router();

router.use(protect);
router.use(roleGuard('admin'));

router.get('/stats', getDashboardStats);
router.get('/turfs', getAllTurfs);
router.post('/turf/status', updateTurfStatus);
router.get('/users', getAllUsers);
router.post('/user/status', updateUserStatus);
router.get('/audit-logs', getAuditLogs);

// Payouts
router.get('/payouts', getAllPayouts);
router.post('/payout/:id/status', updatePayoutStatus);

// User Deletion
router.delete('/user/:id', deleteUser);

module.exports = router;
