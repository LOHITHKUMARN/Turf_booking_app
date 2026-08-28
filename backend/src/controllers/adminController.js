const User = require('../models/User');
const Turf = require('../models/Turf');
const Payout = require('../models/Payout');
const AdminAuditLog = require('../models/AdminAuditLog');
const { sendToUser } = require('../services/notificationService');
const logger = require('../services/logger');

// @desc    Get all turfs
// @route   GET /api/admin/turfs
// @access  Private/Admin
const getAllTurfs = async (req, res) => {
    try {
        const turfs = await Turf.find({}).populate('ownerId', 'name email phone');
        res.json(turfs);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// @desc    Approve or reject turf
// @route   POST /api/admin/turf/status
// @access  Private/Admin
const updateTurfStatus = async (req, res) => {
    const { turfId, status } = req.body;

    try {
        const turf = await Turf.findById(turfId);

        if (turf) {
            turf.status = status;
            const updatedTurf = await turf.save();

            // Log Action
            await AdminAuditLog.create({
                adminId: req.user._id,
                action: status === 'approved' ? 'approve_turf' : 'reject_turf',
                targetId: turf._id,
                targetType: 'Turf',
                ipAddress: req.ip
            });

            // Notify Owner
            const owner = await User.findById(turf.ownerId);
            if (owner) {
                await sendToUser(owner, {
                    title: `Turf ${status === 'approved' ? 'Approved' : 'Suspended'}`,
                    body: `Your turf "${turf.name}" has been ${status} by the administrator.`,
                    data: { turfId: turf._id.toString(), type: 'turf_status_update', status }
                });
            }

            res.json(updatedTurf);
        } else {
            res.status(404).json({ message: 'Turf not found' });
        }
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// @desc    Get all users
// @route   GET /api/admin/users
// @access  Private/Admin
const getAllUsers = async (req, res) => {
    try {
        const users = await User.find({}).select('-password');
        const dbName = User.db.name;
        logger.info(`Admin fetching all users from DB [${dbName}]. Found: ${users.length} users`);
        if (users.length > 0) {
            logger.info(`First user in result: ${users[0].email}`);
        }
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
        const user = await User.findById(userId);

        if (user) {
            user.status = status;
            const updatedUser = await user.save();

            // Log Action
            await AdminAuditLog.create({
                adminId: req.user._id,
                action: status === 'blocked' ? 'block_user' : 'unblock_user',
                targetId: user._id,
                targetType: 'User',
                ipAddress: req.ip
            });

            res.json(updatedUser);
        } else {
            res.status(404).json({ message: 'User not found' });
        }
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// @desc    Get dashboard statistics
// @route   GET /api/admin/stats
// @access  Private/Admin
const getDashboardStats = async (req, res) => {
    try {
        const totalUsers = await User.countDocuments({});
        const pendingTurfs = await Turf.countDocuments({ status: 'pending' });
        const approvedTurfs = await Turf.countDocuments({ status: 'approved' });

        // Calculate Revenue from all completed/confirmed bookings
        const Booking = require('../models/Booking');
        const revenueAgg = await Booking.aggregate([
            { $match: { bookingStatus: { $in: ['completed', 'checked-in', 'confirmed'] } } },
            { $group: { _id: null, total: { $sum: '$totalAmount' } } }
        ]);

        const totalRevenue = revenueAgg[0]?.total || 0;
        const commissionRate = 10; // Fixed 10% for now
        const adminRevenue = (totalRevenue * commissionRate) / 100;

        // Total Payouts (Processed)
        const totalPaidResult = await Payout.aggregate([
            { $match: { status: 'processed' } },
            { $group: { _id: null, total: { $sum: '$amount' } } }
        ]);
        const totalPaid = totalPaidResult[0]?.total || 0;

        // User Growth (Last 6 months)
        const sixMonthsAgo = new Date();
        sixMonthsAgo.setMonth(sixMonthsAgo.getMonth() - 5);
        sixMonthsAgo.setDate(1);
        sixMonthsAgo.setHours(0, 0, 0, 0);

        const userGrowthAgg = await User.aggregate([
            {
                $match: {
                    createdAt: { $gte: sixMonthsAgo }
                }
            },
            {
                $group: {
                    _id: {
                        year: { $year: "$createdAt" },
                        month: { $month: "$createdAt" }
                    },
                    count: { $sum: 1 }
                }
            },
            { $sort: { "_id.year": 1, "_id.month": 1 } }
        ]);

        const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
        const userGrowth = userGrowthAgg.map(item => ({
            month: `${months[item._id.month - 1]} ${item._id.year}`,
            users: item.count
        }));

        res.json({
            totalUsers,
            pendingTurfs,
            approvedTurfs,
            totalRevenue,
            adminRevenue,
            totalPaid,
            commissionRate,
            userGrowth
        });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// @desc    Get Admin Audit Logs
// @route   GET /api/admin/audit-logs
// @access  Private/Admin
const getAuditLogs = async (req, res) => {
    try {
        const logs = await AdminAuditLog.find({})
            .populate('adminId', 'name email')
            .sort({ createdAt: -1 })
            .limit(100); // Pagination could be added here
        res.json(logs);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// @desc    Get all payouts
// @route   GET /api/admin/payouts
// @access  Private/Admin
const getAllPayouts = async (req, res) => {
    try {
        const payouts = await Payout.find({})
            .populate('ownerId', 'name email phone')
            .sort({ requestedAt: -1 });
        res.json(payouts);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// @desc    Update payout status
// @route   POST /api/admin/payout/:id/status
// @access  Private/Admin
const updatePayoutStatus = async (req, res) => {
    const { status } = req.body;
    try {
        const payout = await Payout.findById(req.params.id);

        if (payout) {
            payout.status = status;
            if (status === 'processed') {
                payout.processedAt = Date.now();
            }
            const updatedPayout = await payout.save();

            // Log Action
            await AdminAuditLog.create({
                adminId: req.user._id,
                action: `update_payout_${status}`,
                targetId: payout._id,
                targetType: 'Payout',
                ipAddress: req.ip
            });

            // Notify Owner
            const owner = await User.findById(payout.ownerId);
            if (owner) {
                await sendToUser(owner, {
                    title: `Payout Request ${status === 'processed' ? 'Processed' : 'Failed'}`,
                    body: `Your payout request for ${payout.amount} has been ${status}.`,
                    data: { payoutId: payout._id.toString(), type: 'payout_status_update', status }
                });
            }

            res.json(updatedPayout);
        } else {
            res.status(404).json({ message: 'Payout not found' });
        }
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// @desc    Delete user account
// @route   DELETE /api/admin/user/:id
// @access  Private/Admin
const deleteUser = async (req, res) => {
    try {
        const user = await User.findById(req.params.id);

        if (user) {
            if (user.role === 'admin') {
                return res.status(403).json({ message: 'Cannot delete an administrator account' });
            }

            const userId = user._id;
            await user.deleteOne();
            logger.info(`User deleted: ${userId} by admin ${req.user._id}`);

            // Log Action
            await AdminAuditLog.create({
                adminId: req.user._id,
                action: 'delete_user',
                targetId: userId,
                targetType: 'User',
                ipAddress: req.ip
            });

            res.json({ message: 'User deleted successfully' });
        } else {
            res.status(404).json({ message: 'User not found' });
        }
    } catch (error) {
        logger.error('Error in deleteUser:', error);
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
