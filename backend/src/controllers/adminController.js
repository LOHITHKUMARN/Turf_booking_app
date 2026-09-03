const userRepository = require('../repositories/userRepository');
const turfRepository = require('../repositories/turfRepository');
const adminRepository = require('../repositories/adminRepository');
const { sendToUser } = require('../services/notificationService');
const logger = require('../services/logger');
const { prisma } = require('../config/db');

// @desc    Get all turfs
// @route   GET /api/admin/turfs
// @access  Private/Admin
const getAllTurfs = async (req, res) => {
    try {
        const turfs = await turfRepository.findAllTurfs();
        res.json(turfs);
    } catch (error) {
        logger.error('getAllTurfs error:', error);
        res.status(500).json({ message: error.message });
    }
};

// @desc    Approve or reject turf
// @route   POST /api/admin/turf/status
// @access  Private/Admin
const updateTurfStatus = async (req, res) => {
    const { turfId, status } = req.body;

    try {
        const turf = await turfRepository.findTurfById(turfId);
        if (!turf) {
            return res.status(404).json({ message: 'Turf not found' });
        }

        const updatedTurf = await turfRepository.updateTurfStatus(turfId, status);

        // Log Action
        await adminRepository.logAdminAction({
            adminId: req.user._id || req.user.id,
            action: status === 'approved' ? 'approve_turf' : 'reject_turf',
            targetId: turfId,
            targetType: 'Turf',
            ipAddress: req.ip
        });

        // Notify Owner
        const ownerId = turf.ownerId?._id || turf.ownerId?.id || turf.ownerId;
        const owner = await userRepository.findById(ownerId);
        if (owner) {
            await sendToUser(owner, {
                title: `Turf ${status === 'approved' ? 'Approved' : 'Suspended'}`,
                body: `Your turf "${turf.name}" has been ${status} by the administrator.`,
                data: { turfId: String(turfId), type: 'turf_status_update', status }
            });
        }

        res.json(updatedTurf);
    } catch (error) {
        logger.error('updateTurfStatus error:', error);
        res.status(500).json({ message: error.message });
    }
};

// @desc    Get all users (Customer, Owner, Staff, Admin)
// @route   GET /api/admin/users
// @access  Private/Admin
const getAllUsers = async (req, res) => {
    try {
        const users = await userRepository.findAllUsers();
        logger.info(`Admin fetched all users. Total users: ${users.length}`);
        res.json(users);
    } catch (error) {
        logger.error('Error in getAllUsers:', error);
        res.status(500).json({ message: error.message });
    }
};

// @desc    Block or unblock user
// @route   POST /api/admin/user/status
// @access  Private/Admin
const updateUserStatus = async (req, res) => {
    const { userId, status } = req.body;

    try {
        const user = await userRepository.findById(userId);
        if (!user) {
            return res.status(404).json({ message: 'User not found' });
        }

        const updatedUser = await userRepository.updateUserStatus(userId, status);

        // Log Action
        await adminRepository.logAdminAction({
            adminId: req.user._id || req.user.id,
            action: status === 'blocked' ? 'block_user' : 'unblock_user',
            targetId: userId,
            targetType: 'User',
            ipAddress: req.ip
        });

        res.json(updatedUser);
    } catch (error) {
        logger.error('updateUserStatus error:', error);
        res.status(500).json({ message: error.message });
    }
};

// @desc    Get dashboard statistics
// @route   GET /api/admin/stats
// @access  Private/Admin
const getDashboardStats = async (req, res) => {
    try {
        if (process.env.DB_PROVIDER === 'postgres') {
            const totalUsers = await prisma.user.count();
            const pendingTurfs = await prisma.turf.count({ where: { status: 'pending' } });
            const approvedTurfs = await prisma.turf.count({ where: { status: 'approved' } });

            const bookings = await prisma.booking.findMany({
                where: { bookingStatus: { in: ['completed', 'checked_in', 'confirmed'] } },
                select: { totalAmount: true }
            });

            const totalRevenue = bookings.reduce((sum, b) => sum + Number(b.totalAmount || 0), 0);
            const commissionRate = 10; // Fixed 10%
            const adminRevenue = (totalRevenue * commissionRate) / 100;

            const payouts = await prisma.payout.findMany({
                where: { status: 'processed' },
                select: { amount: true }
            });
            const totalPaid = payouts.reduce((sum, p) => sum + Number(p.amount || 0), 0);

            // User growth dummy/last 6 months
            const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
            const currentMonth = new Date().getMonth();
            const userGrowth = [
                { month: months[(currentMonth - 2 + 12) % 12], users: Math.max(1, totalUsers - 3) },
                { month: months[(currentMonth - 1 + 12) % 12], users: Math.max(1, totalUsers - 1) },
                { month: months[currentMonth], users: totalUsers }
            ];

            return res.json({
                totalUsers,
                pendingTurfs,
                approvedTurfs,
                totalRevenue,
                adminRevenue,
                totalPaid,
                commissionRate,
                userGrowth
            });
        }

        // Mongoose Fallback
        const UserMongo = require('../models/User');
        const TurfMongo = require('../models/Turf');
        const PayoutMongo = require('../models/Payout');
        const BookingMongo = require('../models/Booking');

        const totalUsers = await UserMongo.countDocuments({});
        const pendingTurfs = await TurfMongo.countDocuments({ status: 'pending' });
        const approvedTurfs = await TurfMongo.countDocuments({ status: 'approved' });

        const revenueAgg = await BookingMongo.aggregate([
            { $match: { bookingStatus: { $in: ['completed', 'checked-in', 'confirmed'] } } },
            { $group: { _id: null, total: { $sum: '$totalAmount' } } }
        ]);

        const totalRevenue = revenueAgg[0]?.total || 0;
        const commissionRate = 10;
        const adminRevenue = (totalRevenue * commissionRate) / 100;

        const totalPaidResult = await PayoutMongo.aggregate([
            { $match: { status: 'processed' } },
            { $group: { _id: null, total: { $sum: '$amount' } } }
        ]);
        const totalPaid = totalPaidResult[0]?.total || 0;

        res.json({
            totalUsers,
            pendingTurfs,
            approvedTurfs,
            totalRevenue,
            adminRevenue,
            totalPaid,
            commissionRate,
            userGrowth: []
        });
    } catch (error) {
        logger.error('getDashboardStats error:', error);
        res.status(500).json({ message: error.message });
    }
};

// @desc    Get Admin Audit Logs
// @route   GET /api/admin/audit-logs
// @access  Private/Admin
const getAuditLogs = async (req, res) => {
    try {
        const logs = await adminRepository.findAuditLogs();
        res.json(logs);
    } catch (error) {
        logger.error('getAuditLogs error:', error);
        res.status(500).json({ message: error.message });
    }
};

// @desc    Get all payouts
// @route   GET /api/admin/payouts
// @access  Private/Admin
const getAllPayouts = async (req, res) => {
    try {
        const payouts = await adminRepository.findPayouts();
        res.json(payouts);
    } catch (error) {
        logger.error('getAllPayouts error:', error);
        res.status(500).json({ message: error.message });
    }
};

// @desc    Update payout status
// @route   POST /api/admin/payout/:id/status
// @access  Private/Admin
const updatePayoutStatus = async (req, res) => {
    const { status, statementUrl } = req.body;
    try {
        const updatedPayout = await adminRepository.updatePayoutStatus(req.params.id, status, statementUrl);

        await adminRepository.logAdminAction({
            adminId: req.user._id || req.user.id,
            action: `update_payout_${status}`,
            targetId: req.params.id,
            targetType: 'Payout',
            ipAddress: req.ip
        });

        res.json(updatedPayout);
    } catch (error) {
        logger.error('updatePayoutStatus error:', error);
        res.status(500).json({ message: error.message });
    }
};

// @desc    Delete user account
// @route   DELETE /api/admin/user/:id
// @access  Private/Admin
const deleteUser = async (req, res) => {
    try {
        const user = await userRepository.findById(req.params.id);
        if (!user) {
            return res.status(404).json({ message: 'User not found' });
        }

        if (user.role === 'admin') {
            return res.status(403).json({ message: 'Cannot delete an administrator account' });
        }

        await userRepository.deleteUser(req.params.id);

        await adminRepository.logAdminAction({
            adminId: req.user._id || req.user.id,
            action: 'delete_user',
            targetId: req.params.id,
            targetType: 'User',
            ipAddress: req.ip
        });

        res.json({ message: 'User deleted successfully' });
    } catch (error) {
        logger.error('deleteUser error:', error);
        res.status(500).json({ message: error.message });
    }
};

module.exports = {
    getAllTurfs,
    updateTurfStatus,
    getAllUsers,
    updateUserStatus,
    getDashboardStats,
    getAuditLogs,
    getAllPayouts,
    updatePayoutStatus,
    deleteUser
};
